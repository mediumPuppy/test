const String geometryDrawingSpec = '''
{
  "instructions": {
    "timing": [
      {
        "stage": "draw_grid",
        "startTime": 0,
        "endTime": 3,
        "description": "Draw the multiplication grid",
        "easing": "linear"
      },
      {
        "stage": "draw_labels",
        "startTime": 3,
        "endTime": 6,
        "description": "Label rows and columns",
        "easing": "easeIn"
      },
      {
        "stage": "draw_result",
        "startTime": 6,
        "endTime": 9,
        "description": "Show multiplication result",
        "easing": "easeOut"
      }
    ],
    "drawing": {
      "shapes": [
        {
          "id": "draw_grid",
          "vertices": [
            { "x": 80, "y": 150 },
            { "x": 240, "y": 150 },
            { "x": 240, "y": 270 },
            { "x": 80, "y": 270 }
          ],
          "path": "moveTo(80,150) lineTo(240,150) lineTo(240,270) lineTo(80,270) close() moveTo(120,150) lineTo(120,270) moveTo(160,150) lineTo(160,270) moveTo(200,150) lineTo(200,270) moveTo(80,190) lineTo(240,190) moveTo(80,230) lineTo(240,230)",
          "style": "stroke",
          "strokeWidth": 2,
          "color": "#000000",
          "fadeInRange": [0, 3]
        }
      ],
      "labels": [
        {
          "id": "draw_labels_rows",
          "text": "3 rows",
          "position": { "x": 50, "y": 210 },
          "color": "#ff0000",
          "fadeInRange": [3, 6],
          "handwritten": true
        },
        {
          "id": "draw_labels_cols",
          "text": "4 columns",
          "position": { "x": 160, "y": 130 },
          "color": "#ff0000",
          "fadeInRange": [3, 6],
          "handwritten": true
        },
        {
          "id": "draw_result",
          "text": "3 x 4 = 1 2",
          "position": { "x": 160, "y": 300 },
          "color": "#0000ff",
          "fadeInRange": [6, 9],
          "handwritten": true
        }
      ]
    },
    "speech": {
      "script": "Multiplication is repeated addition. Here, 3 rows of 4 make 12. See how grouping helps simplify math.",
      "pacing": {
        "initialDelay": 0.5,
        "betweenStages": 0.5,
        "finalDelay": 1
      }
    }
  }
}
''';
