FlowChart
=========

Peak Expiatory Flow Rate and Inhaler Usage tracking via HealthKit on iOS

This project was created for my personal use to track the progression of symptoms related to asthma treatment. It is a trivial iOS 9 app with streamlined UX and minimal UI to make recording these values on a daily basis as quick and easy as possible. It additionally provides support for both importing and exporting data to/from Healthkit via CSV file.

The app is written entirely in Swift and stores data in HealthKit. Originally written for Swift 1.1 it is now updated to support Swift 2.2. Note that because of its early origins some of the Swift is not a swifty as I would like at this point. 

The app demonstrates the following in Swift:
* **HealthKit** - Requesting user access, import and export
* **CoreLocation** - Stores location in HealthKit along with peak flow and inhaler entries
* **CSV Parser** - Fully RFC4180 compliant with full unicode support
* **Storyboard UI Layout** - Supports native screen sizes for all iPhone devices.
* **UIDocumentPickerViewController** - Access to reading and saving CSV files from other apps.
 
Disclaimer
=========

I'm not a doctor. There is no medical advice implied here. See full medical disclaimer included with project.
