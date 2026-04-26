use serde::Serialize;

#[derive(Clone, Debug, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
enum CustomField {
    Image(Image),
    Rect(Rect),
}

#[derive(Clone, Debug, Default, Serialize)]
struct Image {
    #[serde(skip_serializing_if = "Option::is_none")]
    texture: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    x: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    y: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    width: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    height: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    alpha: Option<f32>,
    z_index: i32,
}

#[derive(Clone, Debug, Default, Serialize)]
struct Rect {
    #[serde(skip_serializing_if = "Option::is_none")]
    color: Option<String>,
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    alpha: f32,
    z_index: i32,
}

#[derive(Clone, Debug, Default, Serialize)]
struct Column {
    index: u8,
    #[serde(flatten)]
    image: Image,
    single: Image,
    long_head: Image,
    long_body: Image,
    long_tail: Image,
}

#[derive(Clone, Debug, Default, Serialize)]
struct SkinData {
    name: String,
    author: String,
    version: String,
    background: Image,
    columns: Vec<Column>,
    customs: Vec<CustomField>, 
}

fn main() {
    let background = Image {
        x: Some(0.0),
        y: Some(0.0),
        width: Some(1920.0),
        height: Some(1080.0),
        z_index: -1,
        ..Default::default()
    };

    let columns = (0..6).map(|i| {
        let color_idx = match i {
            0 | 2 | 3 | 5 => { 1 },
            _ => { 2 },
        };
        Column {
            index: i as u8,
            image: Image { 
                texture: None, 
                x: Some((200 + i * 120) as f32), 
                y: Some(1080.0), 
                width: Some(120.0), 
                z_index: 0,
                ..Default::default()
            },
            single: Image { 
                texture: Some(format!("res://textures/hit_objects/note{color_idx}.png")), 
                height: Some(40.0), 
                z_index: 3,
                ..Default::default()
            },
            long_head: Image { 
                texture: Some(format!("res://textures/hit_objects/note{}.png", color_idx + 2)), 
                height: Some(40.0), 
                z_index: 3,
                ..Default::default()
            },
            long_body: Image { 
                texture: Some("res://textures/hit_objects/ln_body.png".into()), 
                width: Some(80.0), 
                z_index: 2,
                ..Default::default()
            },
            long_tail: Image { 
                texture: Some("res://textures/hit_objects/ln_tail.png".into()), 
                width: Some(80.0), 
                height: Some(40.0), 
                z_index: 1,
                ..Default::default()
            }
        }
    }).collect::<Vec<_>>();

    let customs = vec![
        CustomField::Image(Image { 
            texture: Some("res://icons/corehexa.png".into()), 
            x: Some(1200.0), 
            y: Some(290.0), 
            width: Some(500.0), 
            height: Some(500.0), 
            alpha: Some(0.5), 
            z_index: 0, 
        }),
        CustomField::Rect(Rect { 
            color: Some("#FFFFFF".into()), 
            x: 200.0, 
            y: 1060.0, 
            width: 720.0, 
            height: 20.0, 
            alpha: 1.0, 
            z_index: 0
        })
    ];

    let skin_data = SkinData {
        name: "Default Skin".into(),
        author: "Team Monokhrom".into(),
        version: "v1".into(),
        background,
        columns,
        customs
    };

    let skin_data_json = serde_json::to_string_pretty(&skin_data).unwrap();
    std::fs::write("skin.json", skin_data_json).unwrap();
}
