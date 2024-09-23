import UIKit
import AVFoundation

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
                    print("Recording failed: \(error.localizedDescription)")
                    return
                }
                print("Recording finished: \(outputFileURL)")
    }
    
    
    // MARK: - Properties
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var movieOutput: AVCaptureMovieFileOutput?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        print("cameraa")
        setupCamera()
    }
    
    // MARK: - Camera Setup
    
    func setupCamera() {
        // Create capture session
        captureSession = AVCaptureSession()
        
        // Configure capture device
        guard let camera = AVCaptureDevice.default(for: .video) else {
            print("Camera not available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession?.addInput(input)
        } catch {
            print("Error setting up camera input: \(error.localizedDescription)")
            return
        }
        
        // Configure video preview layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.insertSublayer(videoPreviewLayer!, at: 0)
        
        // Start the capture session
        captureSession?.startRunning()
    }
    
    // MARK: - User Interaction
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        // Implement recording functionality here
        if movieOutput == nil {
            movieOutput = AVCaptureMovieFileOutput()
            captureSession?.addOutput(movieOutput!)
        }
        
        if let output = movieOutput {
            let outputPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("output.mov")
            output.startRecording(to: outputPath, recordingDelegate: self)
        }
    }
}
