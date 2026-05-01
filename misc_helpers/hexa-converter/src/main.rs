use mania_converter::osu_func::OsuDataLegacy;
use serde::Serialize;

#[derive(Clone, Debug, Serialize)]
struct Meta {
    title: String,
    title_unicode: String,
    artist: String,
    artist_unicode: String,
    creator: String,
    version: String,
    background: String,
    audio: String,
    preview: i32, // 与osu规则相同，未指定时为-1
}

#[derive(Clone, Copy, Debug, Serialize)]
struct TimingPoint {
    time: f64,
    bpm: f64,
}

#[derive(Clone, Copy, Debug, Serialize)]
struct Effect {
    time: f64,
    speed: f64,
}

#[derive(Clone, Copy, Debug, Serialize)]
struct Note {
    time: f64,
    end_time: Option<f64>,
    column: u8,
}

#[derive(Clone, Debug, Serialize)]
struct HexaData {
    meta: Meta,
    timing_points: Vec<TimingPoint>,
    effects: Vec<Effect>,
    notes: Vec<Note>,
}

impl From<OsuDataLegacy> for HexaData {
    fn from(value: OsuDataLegacy) -> Self {
        let meta = Meta {
            title: value.misc.title,
            title_unicode: value.misc.title_unicode,
            artist: value.misc.artist,
            artist_unicode: value.misc.artist_unicode,
            creator: value.misc.creator,
            version: value.misc.version,
            background: value.misc.background,
            audio: value.misc.audio_file_name,
            preview: value.misc.preview_time,
        };

        let timing_points = value
            .timings
            .iter()
            .filter(|&t| t.is_timing)
            .map(|t| TimingPoint {
                time: t.time,
                bpm: 60000f64 / t.val,
            })
            .collect::<Vec<_>>();

        // CoreHexa中的变速与BPM无关，而osu与BPM有关，这里暂时不处理
        let effects = value
            .timings
            .iter()
            .filter(|&t| !t.is_timing)
            .map(|t| Effect {
                time: t.time,
                speed: -100f64 / t.val,
            })
            .collect::<Vec<_>>();

        let to_column = |pos: u32| -> u8 { (pos * value.misc.circle_size / 512) as u8 };

        let notes = value
            .notes
            .iter()
            .map(|h| Note {
                time: h.time as f64,
                end_time: h.end_time.map(|t| t as f64),
                column: to_column(h.x_pos),
            })
            .collect::<Vec<_>>();

        HexaData {
            meta,
            timing_points,
            effects,
            notes,
        }
    }
}

fn main() {
    let chart = "charts/onoken a.k.a. owltree - Melodiniq (TwilightDawnLi) [[22] Linked VERSE FINALE].osu";
    let chart_osu_data = OsuDataLegacy::from_file(chart).unwrap();
    // println!("{:?}", chart_osu_data);
    let chart_hexa_data = HexaData::from(chart_osu_data);
    let chart_hexa_data_json = serde_json::to_string_pretty(&chart_hexa_data).unwrap();
    std::fs::write("melodiniq.json", chart_hexa_data_json).unwrap();
}
