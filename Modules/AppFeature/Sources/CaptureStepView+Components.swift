import SwiftUI
import Capture
import UIKit

struct CaptureStepHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Capture the menu")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            Text("Line up each page so text is readable. Snap every page before processing.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CapturedPagesStripView: View {
    let capturedPages: [CapturedPage]
    let onRemove: (CapturedPage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Captured pages")
                    .font(.headline)
                Spacer()
                if !capturedPages.isEmpty {
                    Text("\(capturedPages.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if capturedPages.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .imageScale(.large)
                        .foregroundStyle(.secondary)
                    Text("No pages yet. Use the shutter to start capturing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(capturedPages) { page in
                            CapturedPageThumbnailView(page: page, onRemove: onRemove)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

struct CaptureControlsView: View {
    let isCaptureInProgress: Bool
    let authorizationStatus: MenuCameraAuthorizationStatus
    let hasCapturedPages: Bool
    let isCameraDisabled: Bool
    let isImportInProgress: Bool
    let onCapture: () -> Void
    let onImportFromLibrary: () -> Void
    let onProcess: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onCapture) {
                Group {
                    if isCaptureInProgress {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else if isCameraDisabled {
                        Label("Add sample page", systemImage: "photo")
                    } else {
                        Label("Capture page", systemImage: "camera.fill")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                isCaptureInProgress ||
                isImportInProgress ||
                (!isCameraDisabled && authorizationStatus != .authorized)
            )

            Button(action: onImportFromLibrary) {
                Group {
                    if isImportInProgress {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Label("Import photos", systemImage: "photo.on.rectangle.angled")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isImportInProgress)

            if hasCapturedPages {
                Button(action: onProcess) {
                    Label("Process menu", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive, action: onReset) {
                    Label("Start over", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct CapturedPageThumbnailView: View {
    let page: CapturedPage
    let onRemove: (CapturedPage) -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = UIImage(contentsOfFile: page.fileURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.secondary
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
            }
        }
        .frame(width: 96, height: 128)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .topTrailing) {
            Button {
                onRemove(page)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.small)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                    .padding(6)
            }
        }
    }
}
