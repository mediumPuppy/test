const String geometryDrawingSpec = '''
{
  "instructions": {
    "timing": [
      {
        "stage": "draw_triangle",
        "startTime": 0,
        "endTime": 2,
        "description": "Drawing the basic triangle."
      },
      {
        "stage": "draw_angle_arc",
        "startTime": 2,
        "endTime": 3,
        "description": "Drawing the angle arc at vertex A."
      },
      {
        "stage": "label_vertices",
        "startTime": 3,
        "endTime": 4,
        "description": "Labeling the vertices A, B, and C."
      },
      {
        "stage": "label_angle",
        "startTime": 4,
        "endTime": 5,
        "description": "Labeling the angle measure at vertex A."
      }
    ],
    "drawing": {
      "shapes": [
        {
          "id": "draw_triangle",
          "path": "moveTo(80,300) lineTo(240,300) lineTo(160,150) close()",
          "style": "stroke",
          "color": "#000000",
          "strokeWidth": 2.0,
          "fadeInRange": [0, 2]
        },
        {
          "id": "draw_angle_arc",
          "path": "moveTo(80,300) arcTo(50,270,60,60,0,1.0,false)",
          "style": "stroke",
          "color": "#FF0000",
          "strokeWidth": 2.0,
          "fadeInRange": [2, 3]
        }
      ],
      "labels": [
        {
          "id": "label_A",
          "text": "A",
          "position": {"x": 60, "y": 280},
          "color": "#0000FF",
          "fadeInRange": [3, 4],
          "handwritten": true
        },
        {
          "id": "label_B",
          "text": "B",
          "position": {"x": 250, "y": 310},
          "color": "#0000FF",
          "fadeInRange": [3, 4],
          "handwritten": false
        },
        {
          "id": "label_C",
          "text": "C",
          "position": {"x": 150, "y": 140},
          "color": "#0000FF",
          "fadeInRange": [3, 4],
          "handwritten": false
        },
        {
          "id": "label_angle",
          "text": "x=zabcdefghijklm",
          "position": {"x": 45, "y": 260},
          "color": "#008000",
          "fadeInRange": [4, 5],
          "handwritten": true
        }
      ]
    },
    "speech": {
      "script": "We are examining a basic triangle with vertices A, B, and C. The red arc illustrates the angle at vertex A, which measures approximately 60 degrees.",
      "pacing": {
        "initialDelay": 1.0,
        "betweenStages": 1.0,
        "finalDelay": 1.0
      }
    }
  }
}

''';
