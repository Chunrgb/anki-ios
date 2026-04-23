use flutter_rust_bridge::frb;
use once_cell::sync::OnceCell;
use parking_lot::Mutex;
use anyhow::{Result, anyhow};
use rusqlite::{Connection, params};
use serde_json::Value;

// ─── Global DB connection ────────────────────────────────────────────────────

static DB: OnceCell<Mutex<Connection>> = OnceCell::new();

fn db() -> Result<&'static Mutex<Connection>> {
    DB.get().ok_or_else(|| anyhow!("Collection not open"))
}

// ─── Public API types ────────────────────────────────────────────────────────

pub struct DeckNode {
    pub id: i64,
    pub name: String,
    pub new_count: u32,
    pub learn_count: u32,
    pub due_count: u32,
    pub children: Vec<DeckNode>,
}

pub struct DueCounts {
    pub new_count: u32,
    pub learn_count: u32,
    pub due_count: u32,
}

pub struct CardForReview {
    pub id: i64,
    pub question_html: String,
    pub answer_html: String,
    pub note_type: String,
}

pub struct NoteInfo {
    pub id: i64,
    pub note_type: String,
    pub fields: Vec<String>,
    pub tags: Vec<String>,
    pub deck_name: String,
    pub due: String,
}

pub struct SyncStatus {
    pub success: bool,
    pub message: String,
}

pub struct CollectionStats {
    pub studied_today: i32,
    pub study_time_minutes: i32,
    pub retention_rate: f64,
    pub streak_days: i32,
    pub forecast: Vec<i32>,
}

// ─── Collection ──────────────────────────────────────────────────────────────

#[frb]
pub async fn open_collection(path: String) -> Result<()> {
    let conn = Connection::open(&path)?;
    conn.execute_batch("PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON;")?;
    DB.set(Mutex::new(conn))
        .map_err(|_| anyhow!("Collection already open"))
}

#[frb]
pub async fn close_collection() -> Result<()> {
    Ok(())
}

// ─── Decks ───────────────────────────────────────────────────────────────────

#[frb]
pub async fn get_deck_tree() -> Result<Vec<DeckNode>> {
    let guard = db()?.lock();
    let decks_json: String = guard
        .query_row("SELECT decks FROM col", [], |r| r.get(0))
        .unwrap_or_else(|_| "{}".to_string());

    let map: Value = serde_json::from_str(&decks_json).unwrap_or(Value::Object(Default::default()));
    let mut nodes = Vec::new();

    if let Value::Object(decks) = map {
        let today = today_days_since_epoch();
        for (_key, v) in &decks {
            let id = v["id"].as_i64().unwrap_or(0);
            let name = v["name"].as_str().unwrap_or("").to_string();
            if name.contains("::") {
                continue; // skip sub-decks for top level
            }
            let (new_c, learn_c, due_c) = due_counts(&guard, id, today);
            nodes.push(DeckNode {
                id,
                name,
                new_count: new_c,
                learn_count: learn_c,
                due_count: due_c,
                children: vec![],
            });
        }
    }

    nodes.sort_by(|a, b| a.name.cmp(&b.name));
    Ok(nodes)
}

#[frb]
pub async fn get_due_counts(deck_id: i64) -> Result<DueCounts> {
    let guard = db()?.lock();
    let today = today_days_since_epoch();
    let (new_c, learn_c, due_c) = due_counts(&guard, deck_id, today);
    Ok(DueCounts { new_count: new_c, learn_count: learn_c, due_count: due_c })
}

#[frb]
pub async fn add_deck(name: String) -> Result<()> {
    let guard = db()?.lock();
    let decks_json: String = guard
        .query_row("SELECT decks FROM col", [], |r| r.get(0))
        .unwrap_or_else(|_| "{}".to_string());
    let mut map: Value =
        serde_json::from_str(&decks_json).unwrap_or(Value::Object(Default::default()));
    let id = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_millis() as i64;
    if let Value::Object(ref mut m) = map {
        m.insert(
            id.to_string(),
            serde_json::json!({ "id": id, "name": name, "conf": 1, "type": 0 }),
        );
    }
    guard.execute(
        "UPDATE col SET decks = ?1",
        params![serde_json::to_string(&map)?],
    )?;
    Ok(())
}

#[frb]
pub async fn delete_deck(deck_id: i64) -> Result<()> {
    let guard = db()?.lock();
    guard.execute("DELETE FROM cards WHERE did = ?1", params![deck_id])?;
    let decks_json: String = guard
        .query_row("SELECT decks FROM col", [], |r| r.get(0))
        .unwrap_or_else(|_| "{}".to_string());
    let mut map: Value =
        serde_json::from_str(&decks_json).unwrap_or(Value::Object(Default::default()));
    if let Value::Object(ref mut m) = map {
        m.remove(&deck_id.to_string());
    }
    guard.execute(
        "UPDATE col SET decks = ?1",
        params![serde_json::to_string(&map)?],
    )?;
    Ok(())
}

// ─── Review ──────────────────────────────────────────────────────────────────

#[frb]
pub async fn get_next_card(deck_id: i64) -> Result<Option<CardForReview>> {
    let guard = db()?.lock();
    let today = today_days_since_epoch() as i64;

    // New cards first, then due reviews
    let card_row: Option<(i64, i64)> = guard
        .query_row(
            "SELECT c.id, c.nid FROM cards c \
             WHERE c.did = ?1 AND (c.queue = 0 OR (c.queue = 2 AND c.due <= ?2)) \
             ORDER BY c.due ASC LIMIT 1",
            params![deck_id, today],
            |r| Ok((r.get(0)?, r.get(1)?)),
        )
        .ok();

    let (card_id, note_id) = match card_row {
        Some(row) => row,
        None => return Ok(None),
    };

    let (flds, mid): (String, i64) = guard.query_row(
        "SELECT flds, mid FROM notes WHERE id = ?1",
        params![note_id],
        |r| Ok((r.get(0)?, r.get(1)?)),
    )?;

    let fields: Vec<&str> = flds.split('\x1f').collect();
    let question = fields.first().map(|s| s.to_string()).unwrap_or_default();
    let answer = fields.get(1).map(|s| s.to_string()).unwrap_or_default();

    let note_type = guard
        .query_row(
            "SELECT name FROM notetypes WHERE id = ?1",
            params![mid],
            |r| r.get::<_, String>(0),
        )
        .unwrap_or_else(|_| "Basic".to_string());

    Ok(Some(CardForReview {
        id: card_id,
        question_html: question,
        answer_html: answer,
        note_type,
    }))
}

#[frb]
pub async fn answer_card(card_id: i64, ease: u8, time_taken_ms: u32) -> Result<()> {
    let guard = db()?.lock();
    let today = today_days_since_epoch() as i64;
    let now_ms = now_ms();

    let (queue, interval, factor): (i64, i64, i64) = guard.query_row(
        "SELECT queue, ivl, factor FROM cards WHERE id = ?1",
        params![card_id],
        |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?)),
    )?;

    let (new_queue, new_interval, new_factor, new_due) =
        schedule(queue, interval, factor, ease, today);

    guard.execute(
        "UPDATE cards SET queue=?1, ivl=?2, factor=?3, due=?4, reps=reps+1, mod=?5, \
         type=CASE WHEN type=0 THEN 2 ELSE type END \
         WHERE id=?6",
        params![new_queue, new_interval, new_factor, new_due, now_ms / 1000, card_id],
    )?;

    guard.execute(
        "INSERT INTO revlog (id, cid, usn, ease, ivl, lastIvl, factor, time, type) \
         VALUES (?1, ?2, -1, ?3, ?4, ?5, ?6, ?7, 1)",
        params![now_ms, card_id, ease, new_interval, interval, new_factor, time_taken_ms],
    )?;

    Ok(())
}

#[frb]
pub async fn undo_last_answer() -> Result<()> {
    Ok(()) // simplified
}

// ─── Browser ─────────────────────────────────────────────────────────────────

#[frb]
pub async fn search_notes(query: String, limit: u32) -> Result<Vec<NoteInfo>> {
    let guard = db()?.lock();
    let pattern = format!("%{}%", query);
    let mut stmt = guard.prepare(
        "SELECT n.id, n.flds, n.mid, n.tags, c.did \
         FROM notes n JOIN cards c ON c.nid = n.id \
         WHERE n.flds LIKE ?1 LIMIT ?2",
    )?;

    let decks_json: String = guard
        .query_row("SELECT decks FROM col", [], |r| r.get(0))
        .unwrap_or_else(|_| "{}".to_string());
    let deck_map: Value =
        serde_json::from_str(&decks_json).unwrap_or(Value::Object(Default::default()));

    let rows = stmt.query_map(params![pattern, limit], |r| {
        Ok((
            r.get::<_, i64>(0)?,
            r.get::<_, String>(1)?,
            r.get::<_, i64>(2)?,
            r.get::<_, String>(3)?,
            r.get::<_, i64>(4)?,
        ))
    })?;

    let mut results = Vec::new();
    for row in rows {
        let (id, flds, mid, tags, did) = row?;
        let fields: Vec<String> = flds.split('\x1f').map(str::to_string).collect();
        let note_type = guard
            .query_row(
                "SELECT name FROM notetypes WHERE id = ?1",
                params![mid],
                |r| r.get::<_, String>(0),
            )
            .unwrap_or_else(|_| "Basic".to_string());
        let deck_name = deck_map[did.to_string()]["name"]
            .as_str()
            .unwrap_or("Default")
            .to_string();
        let tag_list: Vec<String> = tags.split_whitespace().map(str::to_string).collect();
        results.push(NoteInfo {
            id,
            note_type,
            fields,
            tags: tag_list,
            deck_name,
            due: String::new(),
        });
    }
    Ok(results)
}

// ─── Sync ─────────────────────────────────────────────────────────────────────

#[frb]
pub async fn sync_collection(_username: String, _password: String) -> Result<SyncStatus> {
    Ok(SyncStatus {
        success: false,
        message: "Sync not implemented yet".to_string(),
    })
}

// ─── Stats ───────────────────────────────────────────────────────────────────

#[frb]
pub async fn get_collection_stats() -> Result<CollectionStats> {
    let guard = db()?.lock();
    let today_start = today_days_since_epoch() as i64;
    let day_ms = today_start * 86400 * 1000;

    let studied_today: i32 = guard
        .query_row(
            "SELECT COUNT(*) FROM revlog WHERE id >= ?1",
            params![day_ms],
            |r| r.get(0),
        )
        .unwrap_or(0);

    let time_ms: i64 = guard
        .query_row(
            "SELECT COALESCE(SUM(time), 0) FROM revlog WHERE id >= ?1",
            params![day_ms],
            |r| r.get(0),
        )
        .unwrap_or(0);

    let total_reviews: i64 = guard
        .query_row("SELECT COUNT(*) FROM revlog", [], |r| r.get(0))
        .unwrap_or(0);

    let correct_reviews: i64 = guard
        .query_row(
            "SELECT COUNT(*) FROM revlog WHERE ease > 1",
            [],
            |r| r.get(0),
        )
        .unwrap_or(0);

    let retention = if total_reviews > 0 {
        correct_reviews as f64 / total_reviews as f64
    } else {
        0.0
    };

    Ok(CollectionStats {
        studied_today,
        study_time_minutes: (time_ms / 60000) as i32,
        retention_rate: retention,
        streak_days: 0,
        forecast: vec![0; 30],
    })
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

fn today_days_since_epoch() -> u32 {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();
    (secs / 86400) as u32
}

fn now_ms() -> i64 {
    use std::time::{SystemTime, UNIX_EPOCH};
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis() as i64
}

fn due_counts(conn: &Connection, deck_id: i64, today: u32) -> (u32, u32, u32) {
    let new_c: u32 = conn
        .query_row(
            "SELECT COUNT(*) FROM cards WHERE did=?1 AND queue=0",
            params![deck_id],
            |r| r.get(0),
        )
        .unwrap_or(0);
    let learn_c: u32 = conn
        .query_row(
            "SELECT COUNT(*) FROM cards WHERE did=?1 AND queue=1",
            params![deck_id],
            |r| r.get(0),
        )
        .unwrap_or(0);
    let due_c: u32 = conn
        .query_row(
            "SELECT COUNT(*) FROM cards WHERE did=?1 AND queue=2 AND due<=?2",
            params![deck_id, today as i64],
            |r| r.get(0),
        )
        .unwrap_or(0);
    (new_c, learn_c, due_c)
}

fn schedule(
    queue: i64,
    interval: i64,
    factor: i64,
    ease: u8,
    today: i64,
) -> (i64, i64, i64, i64) {
    let factor = if factor == 0 { 2500 } else { factor };
    match ease {
        1 => {
            // Again
            (1, 1, (factor - 200).max(1300), today + 1)
        }
        2 => {
            // Hard
            let new_ivl = ((interval as f64 * 1.2).round() as i64).max(interval + 1);
            (2, new_ivl, (factor - 150).max(1300), today + new_ivl)
        }
        3 => {
            // Good
            let new_ivl =
                ((interval as f64 * factor as f64 / 1000.0).round() as i64).max(interval + 1);
            (2, new_ivl, factor, today + new_ivl)
        }
        _ => {
            // Easy
            let new_ivl = ((interval as f64 * factor as f64 / 1000.0 * 1.3).round() as i64)
                .max(interval + 1);
            (2, new_ivl, (factor + 150).min(9999), today + new_ivl)
        }
    }
}
