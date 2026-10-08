# Member 4 — Heritage route flow (FR12)

Open **Dashboard → Heritage Map & Navigation**, or press **Start Tour** on an existing tour's details page. Existing tours load their ordered destinations and coordinates from the current backend's place API.

The seven views follow the supplied prototype: route map, GPS location, start tour, active tour, directions, checkpoint progress, and completion summary. Map, Tours and Saved navigation stays available. The implementation uses the prototype's brown/cream palette and rounded cards.

Run from `frontend`: `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter run`. Android and iOS foreground location declarations are included. Allow location access and use Refresh Location to activate GPS. Internet access is needed for OpenStreetMap tiles and OSRM driving directions.

For a standalone review without login, run `flutter run -t lib/member4_main.dart`. The coastal route is a sample itinerary; GPS data is never simulated.

Verification in this editing session was blocked: shell launches returned Windows Access denied, including the approved retry. Flutter dependency resolution, formatting, analyzer and test execution could not be confirmed. Run the commands above before claiming a working build.

Journey CRUD: begin a tour (create), open Saved and resume/view it (read), mark/undo checkpoints or rename it (update), and delete it with confirmation (delete). Data uses the existing secure storage dependency and remains on the device; dashboard journeys are scoped to the account ID. Tour-details entry currently uses the device scope.

## Prototype deviations and remaining evaluation

- Real interactive map tiles replace the prototype's illustrated maps. OpenStreetMap attribution is displayed.
- Routing uses OSRM's public driving endpoint. Estimates exclude visits. Directions are an ordered maneuver list; automatic rerouting, automatic instruction advancement, voice/audio guides and background GPS are not implemented. Recalculate Route uses the latest GPS reading and remaining stops.
- Checkpoints are explicitly marked by the user and can be undone. Reaching a location does not automatically mark it visited.
- Recorded distance includes valid foreground GPS samples only; it is not the prototype's fixed 126 km. Checkpoint saves persist that distance. Location tracking stops when the screen is closed.
- Completion badges are journey-local indicators, not backend profile rewards. Copy Tour Summary supports pasting into another app instead of a native share sheet.
- Saved journey storage does not add new server-side entities or sync across devices. The seven screens expose the operations relevant to their flow; this does not establish compliance with the assignment's literal two-CRUD-operations-per-interface requirement.

## Functional checks

Automated model tests cover bounded completion, undo, persistence round trips and invalid coordinates. Device checks still needed: permission denial and recovery; live GPS readings; road directions and offline recovery; completing five checkpoints; closing and resuming a journey; renaming/deleting a saved journey; and starting a backend-created itinerary.

Do not report usability results without conducting the required participant sessions. Record observed results and screenshots from the running app in the consolidated report.
