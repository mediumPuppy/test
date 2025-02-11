const String geometryDrawingSpec = '''
{
  "instructions": {
    "timing": [
      {
        "stage": "draw_line",
        "startTime": 0.0,
        "endTime": 2.0,
        "description": "Draw a straight line (Line AB).",
        "easing": "easeIn"
      },
      {
        "stage": "label_line",
        "startTime": 2.5,
        "endTime": 3.0,
        "description": "Label the line.",
        "easing": "linear"
      },
      {
        "stage": "draw_segment",
        "startTime": 3.5,
        "endTime": 5.0,
        "description": "Draw a line segment (Segment CD).",
        "easing": "easeIn"
      },
      {
        "stage": "label_segment",
        "startTime": 5.5,
        "endTime": 6.0,
        "description": "Label the line segment.",
        "easing": "linear"
      },
      {
        "stage": "draw_ray",
        "startTime": 6.5,
        "endTime": 8.0,
        "description": "Draw a ray (Ray EF).",
        "easing": "easeIn"
      },
      {
        "stage": "label_ray",
        "startTime": 8.5,
        "endTime": 9.0,
        "description": "Label the ray.",
        "easing": "linear"
      },
      {
        "stage": "draw_angle",
        "startTime": 9.5,
        "endTime": 11.0,
        "description": "Draw an angle (Angle G).",
        "easing": "easeIn"
      },
      {
        "stage": "label_angle",
        "startTime": 11.5,
        "endTime": 12.0,
        "description": "Label the angle.",
        "easing": "linear"
      },
      {
        "stage": "draw_rectangle",
        "startTime": 12.5,
        "endTime": 14.0,
        "description": "Draw a rectangle (ABCD).",
        "easing": "easeIn"
      },
      {
        "stage": "label_rectangle",
        "startTime": 14.5,
        "endTime": 16.0,
        "description": "Label the rectangle.",
        "easing": "linear"
      }
    ],
    "drawing": {
      "shapes": [
        {
          "id": "draw_line",
          "vertices": [
            { "x": 30, "y": 100 },
            { "x": 290, "y": 100 }
          ],
          "path": "moveTo(30, 100) lineTo(290, 100)",
          "style": "stroke",
          "strokeWidth": 3,
          "color": "#000000",
          "fadeInRange": [0.0, 0.5]
        },
        {
          "id": "draw_segment",
          "vertices": [
            { "x": 30, "y": 150 },
            { "x": 180, "y": 150 }
          ],
          "path": "moveTo(30, 150) lineTo(180, 150)",
          "style": "stroke",
          "strokeWidth": 3,
          "color": "#000000",
          "fadeInRange": [3.5, 4.0]
        },
        {
          "id": "draw_ray",
          "vertices": [
            { "x": 30, "y": 220 },
            { "x": 270, "y": 220 },
            { "x": 265, "y": 215 },
            { "x": 270, "y": 220 },
            { "x": 265, "y": 225 }
          ],
          "path": "moveTo(30, 220) lineTo(270, 220) lineTo(265, 215) moveTo(270, 220) lineTo(265, 225)",
          "style": "stroke",
          "strokeWidth": 3,
          "color": "#000000",
          "fadeInRange": [6.5, 7.0]
        },
        {
          "id": "draw_angle",
          "vertices": [
            { "x": 100, "y": 300 },
            { "x": 160, "y": 260 },
            { "x": 100, "y": 300 },
            { "x": 50, "y": 260 }
          ],
          "path": "moveTo(100, 300) lineTo(160, 260) moveTo(100, 300) lineTo(50, 260)",
          "style": "stroke",
          "strokeWidth": 3,
          "color": "#000000",
          "fadeInRange": [9.5, 10.0]
        },
        {
          "id": "draw_rectangle",
          "vertices": [
            { "x": 30, "y": 350 },
            { "x": 130, "y": 350 },
            { "x": 130, "y": 400 },
            { "x": 30, "y": 400 },
            { "x": 30, "y": 350 }
          ],
          "path": "moveTo(30, 350) lineTo(130, 350) lineTo(130, 400) lineTo(30, 400) lineTo(30, 350)",
          "style": "stroke",
          "strokeWidth": 3,
          "color": "#000000",
          "fadeInRange": [12.5, 13.0]
        }
      ],
      "labels": [
        {
          "id": "label_line",
          "text": "Line AB",
          "position": { "x": 160, "y": 80 },
          "color": "#000000",
          "fadeInRange": [2.5, 3.0]
        },
        {
          "id": "label_segment",
          "text": "Segment CD",
          "position": { "x": 90, "y": 130 },
          "color": "#000000",
          "fadeInRange": [5.5, 6.0]
        },
        {
          "id": "label_ray",
          "text": "Ray EF",
          "position": { "x": 150, "y": 200 },
          "color": "#000000",
          "fadeInRange": [8.5, 9.0]
        },
        {
          "id": "label_angle",
          "text": "Angle G",
          "position": { "x": 80, "y": 270 },
          "color": "#000000",
          "fadeInRange": [11.5, 12.0]
        },
        {
          "id": "label_rectangle",
          "text": "Rectangle ABCD",
          "position": { "x": 35, "y": 345 },
          "color": "#000000",
          "fadeInRange": [14.5, 15.0]
        }
      ]
    },
    "speech": {
      "script": "Let's explore some basic elements of geometry: a line, a segment, a ray, an angle, and a rectangle. Notice how each is drawn and labeled in turn. These fundamental figures form the basis of many geometric constructions.",
      "pacing": {
        "initialDelay": 1.0,
        "betweenStages": 0.5,
        "finalDelay": 1.0
      }
    }
  }
}
''';
