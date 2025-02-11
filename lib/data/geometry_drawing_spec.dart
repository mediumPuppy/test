const String geometryDrawingSpec = '''{
  "instructions": {
    "timing": [
      {
        "stage": "draw_triangle",
        "startTime": 0,
        "endTime": 2,
        "description": "Drawing triangle ΔABC."
      },
      {
        "stage": "label_vertices",
        "startTime": 2,
        "endTime": 3,
        "description": "Labeling vertices A, B, and C."
      },
      {
        "stage": "mark_angles",
        "startTime": 3,
        "endTime": 5,
        "description": "Drawing angle arcs and labeling angles."
      }
    ],
    "drawing": {
      "shapes": [
        {
          "id": "draw_triangle",
          "vertices": [
            { "x": 60, "y": 100 },
            { "x": 260, "y": 100 },
            { "x": 160, "y": 300 }
          ],
          "path": "moveTo(60,100) lineTo(260,100) lineTo(160,300) lineTo(60,100)",
          "style": "stroke",
          "strokeWidth": 3,
          "color": "#0000FF",
          "fadeInRange": [0, 2]
        },
        {
          "id": "mark_angles",
          "path": "moveTo(60,100) arcTo(60,100,40,40,0,0.8,true) moveTo(260,100) arcTo(260,100,40,40,3.14,0.7,true) moveTo(160,300) arcTo(160,300,40,40,4.71,0.9,true)",
          "style": "stroke",
          "strokeWidth": 2,
          "color": "#FF0000",
          "fadeInRange": [3, 5]
        }
      ],
      "labels": [
        {
          "id": "label_A",
          "text": "A",
          "position": { "x": 45, "y": 85 },
          "color": "#000000",
          "fadeInRange": [2, 3]
        },
        {
          "id": "label_B",
          "text": "B",
          "position": { "x": 265, "y": 85 },
          "color": "#000000",
          "fadeInRange": [2, 3]
        },
        {
          "id": "label_C",
          "text": "C",
          "position": { "x": 155, "y": 315 },
          "color": "#000000",
          "fadeInRange": [2, 3]
        },
        {
          "id": "angle_A",
          "text": "∠A",
          "position": { "x": 80, "y": 120 },
          "color": "#000000",
          "fadeInRange": [3, 5]
        },
        {
          "id": "angle_B",
          "text": "∠B",
          "position": { "x": 245, "y": 120 },
          "color": "#000000",
          "fadeInRange": [3, 5]
        },
        {
          "id": "angle_C",
          "text": "∠C",
          "position": { "x": 180, "y": 280 },
          "color": "#000000",
          "fadeInRange": [3, 5]
        }
      ]
    },
    "speech": {
      "script": "Today we explore triangles and basic angles. We draw triangle ABC, label its vertices, and highlight the angles at each corner to understand their measures.",
      "pacing": {
        "initialDelay": 1,
        "betweenStages": 1,
        "finalDelay": 1
      }
    }
  }
}
''';
