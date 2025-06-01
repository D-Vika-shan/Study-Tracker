# Study Tracker

A Flutter application that allows users to manage tasks, subjects, chapters, and topics using Firebase as the backend. Users can add, edit, and delete tasks, as well as track their progress.

## Features

- **User Authentication**: Users can sign in anonymously.
- **Task Management**: Add, edit, and delete tasks with deadlines.
- **Subject Management**: Organize tasks into subjects, chapters, and topics.
- **Progress Tracking**: Track completion progress of tasks and topics.
- **Responsive UI**: A sleek and user-friendly interface built with Flutter.

<p float="left">
  <img src="assets/screenshots/Home%20pg%20ss.png" width="30%" />
  <img src="assets/screenshots/Side%20bar%20ss.png" width="30%" />
  <img src="assets/screenshots/Subject%20pg%20ss.png" width="30%" />
</p>
<p float="left">
    ![Chapters Page](assets/screenshots/Chapter%20pg%20ss.png)
    ![Topics Page](assets/screenshots/Topic%20pg%20ss.png)
</p>

## Technologies Used

- **Flutter**: The UI framework for building natively compiled applications.
- **Firebase**: Used for authentication and Firestore database.
- **Intl**: For date formatting.
- **Percent Indicator**: To visually represent completion percentages.

## Getting Started

### Prerequisites

- Flutter SDK installed on your machine.
- A Firebase project set up with Firestore and Authentication enabled.

### Installation

1. **Clone the repository**:

   ```bash
   git clone https://github.com/yourusername/task_management_app.git
   cd task_management_app

2. **Install dependencies**:
    ```bash
    flutter pub get

3. **Setup Firebase**:

- Create a Firebase project in the Firebase Console.
- Add your app to the Firebase project and download the google-services.json (for Android) or GoogleService-Info.plist (for iOS).
- Follow the instructions to integrate Firebase into your Flutter app.

4. **Configure Firebase Options**:

- Update the firebase_options.dart file with your Firebase configuration.
- Run the app:

    ```bash
    flutter run

## Usage:
- Launch the app, and you will be signed in anonymously.
- Use the floating action button to add new tasks.
- Swipe left on tasks to delete them.
- Navigate through subjects, chapters, and topics to organize your tasks.

## Future Enhancements:
- Implement user registration and login functionality.
- Add notifications for upcoming deadlines.
- Enhance the UI with animations and transitions.

## License
This project is licensed under the MIT License. See the LICENSE file for details.
