# New Video Creation Feature - Step-by-Step Plan

- [ ] **Detect Last Video in Topic**
  - [ ] In the video feed screen, determine if the current video is the last video in the current topic.
  - [ ] Use the topic identifier (e.g., `topicId`) to filter videos and detect if the current index equals the last index.

- [ ] **Display "Create New Video?" Button**
  - [ ] Modify the video feed screen to conditionally render a button labeled "Create new video?" when the user reaches the last video in a topic.
  - [ ] Ensure the button is clearly visible and styled consistently with the UI.

- [ ] **Handle Button Click**
  - [ ] On clicking the button, capture the current topic (e.g., `topicId` or topic name).
  - [ ] Form a prompt message for GPT-4O Mini that includes:
    - The current topic: "Your topic is: [current topic]"
    - A request: "Create a 15-25 second video explaining this concept."
    - Append the instructions from `instructions.md`.

- [ ] **Send Prompt to GPT-4O Mini**
  - [ ] Make an API call to GPT-4O Mini with the composed prompt.
  - [ ] Ensure error handling in case the API call fails.

- [ ] **Parse and Validate GPT Response**
  - [ ] Extract the JSON substring from the first opening `{` to the last closing `}`.
  - [ ] Validate that the parsed response is valid JSON.
  - [ ] If invalid, display an error message or offer a retry option.

- [ ] **Create a New Video Entry**
  - [ ] Use the default values from `sample_videos.dart` (copy all fields except for `videoJson`).
  - [ ] Replace the `videoJson` field with the validated JSON received from GPT-4O Mini.
  - [ ] Ensure that the new video entry gets a unique ID if necessary.

- [ ] **Persist the New Video**
  - [ ] Insert the new video into the database (or update the local state) as per existing video creation logic.
  - [ ] Confirm that the new video appears in the video feed immediately.

- [ ] **Update the UI**
  - [ ] Refresh the video feed to include the newly created video.
  - [ ] Optionally, notify the user that a new video has been added.

- [ ] **Testing and Error Handling**
  - [ ] Test the entire workflow to ensure:
    - The end-of-topic is correctly detected.
    - The "Create new video?" button appears only when expected.
    - The GPT-4O Mini API call returns valid JSON.
    - The JSON is correctly parsed and incorporates into the new video entry.
    - The user interface updates correctly without breaking other features.
  - [ ] Handle API errors and invalid JSON responses gracefully. 