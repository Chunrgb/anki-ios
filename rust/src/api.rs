use anki::collection::{Collection, CollectionBuilder};
use anki::decks::DeckId;
use anki::scheduler::answering::CardAnswer;
use flutter_rust_bridge::frb;
use once_cell::sync::OnceCell;
use parking_lot::Mutex;
use anyhow::Result;
use std::sync::Arc;

// ─── Global collection ──────────────────────────────────────────────────────

static COLLECTION: OnceCell<Arc<Mutex<Collection>>> = OnceCell::new();

fn col() -> Result<Arc<Mutex<Collection>>> {
    COLLECTION.get().cloned().ok_or_else(|| anyhow::anyhow!("Collection not open"))
}

// ─── Public API types ────────────────────────────────────────────────────────

#[frb(dart_metadata=("freezed"))]
pub struct DeckNode {
    pub id: i64,
    pub name: String,
    pub new_count: u32,
    pub learn_count: u32,
    pub due_count: u32,
    pub children: Vec<DeckNode>,
}

#[frb(dart_metadata=("freezed"))]
pub struct DueCounts {
    pub new_count: u32,
    pub learn_count: u32,
    pub due_count: u32,
}

#[frb(dart_metadata=("freezed"))]
pub struct CardForReview {
    pub id: i64,
    pub question_html: String,
    pub answer_html: String,
    pub note_type: String,
}

#[frb(dart_metadata=("freezed"))]
pub struct NoteInfo {
    pub id: i64,
    pub note_type: String,
    pub fields: Vec<String>,
    pub tags: Vec<String>,
    pub deck_name: String,
    pub due: String,
}

#[frb(dart_metadata=("freezed"))]
pub struct SyncStatus {
    pub success: bool,
    pub message: String,
}

#[frb(dart_metadata=("freezed"))]
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
    let col = CollectionBuilder::new(&path).build()?;
    COLLECTION.set(Arc::new(Mutex::new(col))).map_err(|_| anyhow::anyhow!("Collection already open"))?;
    Ok(())
}

#[frb]
pub async fn close_collection() -> Result<()> {
    // Collection is dropped when the Arc ref count reaches zero.
    // For explicit close we just flush the DB.
    if let Some(col_arc) = COLLECTION.get() {
        col_arc.lock().storage.db.flush()?;
    }
    Ok(())
}

// ─── Decks ───────────────────────────────────────────────────────────────────

#[frb]
pub async fn get_deck_tree() -> Result<Vec<DeckNode>> {
    let col = col()?;
    let mut guard = col.lock();
    let tree = guard.deck_tree(Some(chrono::Utc::now().timestamp()))?;
    Ok(tree.children.iter().map(node_to_dart).collect())
}

fn node_to_dart(n: &anki::decks::DeckTreeNode) -> DeckNode {
    DeckNode {
        id: n.deck_id,
        name: n.name.clone(),
        new_count: n.new_count,
        learn_count: n.learn_count,
        due_count: n.due_count,
        children: n.children.iter().map(node_to_dart).collect(),
    }
}

#[frb]
pub async fn get_due_counts(deck_id: i64) -> Result<DueCounts> {
    let col = col()?;
    let mut guard = col.lock();
    let counts = guard.due_counts(DeckId(deck_id))?;
    Ok(DueCounts {
        new_count: counts.new as u32,
        learn_count: counts.learn as u32,
        due_count: counts.due as u32,
    })
}

#[frb]
pub async fn add_deck(name: String) -> Result<()> {
    let col = col()?;
    col.lock().get_or_create_normal_deck(&name)?;
    Ok(())
}

#[frb]
pub async fn delete_deck(deck_id: i64) -> Result<()> {
    let col = col()?;
    col.lock().remove_decks_and_child_decks(&[DeckId(deck_id)])?;
    Ok(())
}

// ─── Review ──────────────────────────────────────────────────────────────────

#[frb]
pub async fn get_next_card(deck_id: i64) -> Result<Option<CardForReview>> {
    let col = col()?;
    let mut guard = col.lock();

    guard.set_current_deck(DeckId(deck_id))?;

    let card = match guard.get_next_card()? {
        Some(c) => c,
        None => return Ok(None),
    };

    let note = guard.storage.get_note(card.note_id)?.ok_or_else(|| anyhow::anyhow!("Note not found"))?;
    let notetype = guard.get_notetype(note.notetype_id)?.ok_or_else(|| anyhow::anyhow!("Notetype not found"))?;

    let question = guard.render_card_question(&card, &note, &notetype)?;
    let answer = guard.render_card_answer(&card, &note, &notetype)?;

    Ok(Some(CardForReview {
        id: card.id.0,
        question_html: question,
        answer_html: answer,
        note_type: notetype.name.clone(),
    }))
}

#[frb]
pub async fn answer_card(card_id: i64, ease: u8, time_taken_ms: u32) -> Result<()> {
    let col = col()?;
    let mut guard = col.lock();

    let answer = CardAnswer {
        card_id: anki::card::CardId(card_id),
        current_decks_id: guard.get_current_deck_id()?,
        ease,
        elapsed_secs: (time_taken_ms / 1000) as u32,
        manual_ease_factor: None,
        new_custom_data: None,
    };

    guard.answer_card(&answer)?;
    Ok(())
}

#[frb]
pub async fn undo_last_answer() -> Result<()> {
    col()?.lock().undo()?;
    Ok(())
}

// ─── Browser ─────────────────────────────────────────────────────────────────

#[frb]
pub async fn search_notes(query: String, limit: u32) -> Result<Vec<NoteInfo>> {
    let col = col()?;
    let mut guard = col.lock();

    let note_ids = guard.search_notes(&query)?;
    let mut results = Vec::new();

    for note_id in note_ids.iter().take(limit as usize) {
        let note = match guard.storage.get_note(*note_id)? {
            Some(n) => n,
            None => continue,
        };
        let notetype = match guard.get_notetype(note.notetype_id)? {
            Some(nt) => nt,
            None => continue,
        };

        let deck_name = guard
            .get_deck(guard.first_card_deck_for_note(*note_id)?)?
            .map(|d| d.name.to_string())
            .unwrap_or_default();

        results.push(NoteInfo {
            id: note_id.0,
            note_type: notetype.name.clone(),
            fields: note.fields().map(str::to_string).collect(),
            tags: note.tags.clone(),
            deck_name,
            due: String::new(),
        });
    }

    Ok(results)
}

// ─── Sync ─────────────────────────────────────────────────────────────────────

#[frb]
pub async fn sync_collection(username: String, password: String) -> Result<SyncStatus> {
    use anki::sync::{NormalSyncer, SyncAuth};

    let col = col()?;
    let auth = SyncAuth { hkey: String::new(), endpoint: None };

    // Obtain hkey via login first
    let login_result = anki::sync::ankiweb_login(&username, &password, None).await;
    match login_result {
        Ok(hkey) => {
            let auth = SyncAuth { hkey, endpoint: None };
            let col_clone = Arc::clone(&col);
            let result = tokio::task::spawn_blocking(move || {
                let mut guard = col_clone.lock();
                // Normal sync
                guard.normal_sync(auth)
            })
            .await??;

            Ok(SyncStatus { success: true, message: format!("Sync complete") })
        }
        Err(e) => Ok(SyncStatus { success: false, message: e.to_string() }),
    }
}

// ─── Stats ───────────────────────────────────────────────────────────────────

#[frb]
pub async fn get_collection_stats() -> Result<CollectionStats> {
    let col = col()?;
    let mut guard = col.lock();

    let stats = guard.studied_today()?;
    let forecast = guard.due_tree_forecast(30)?;

    Ok(CollectionStats {
        studied_today: stats.cards as i32,
        study_time_minutes: (stats.time_secs / 60) as i32,
        retention_rate: if stats.reviews > 0 {
            (stats.reviews - stats.failed) as f64 / stats.reviews as f64
        } else {
            0.0
        },
        streak_days: guard.streak_days()? as i32,
        forecast: forecast.iter().map(|d| d.due as i32).collect(),
    })
}
