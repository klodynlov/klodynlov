import SwiftUI
import PhotosUI
import UIKit
import KaribTruckCore

/// Traçabilité réception : photo d'étiquette + produit + fournisseur + lot + DLC.
/// La photo est rangée hors journal ; son empreinte SHA-256, elle, est scellée.
struct ReceptionView: View {
    @EnvironmentObject private var store: Store

    @State private var product = ""
    @State private var supplier = ""
    @State private var lot = ""
    @State private var dlc = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
    @State private var photo: UIImage?
    @State private var photoData: Data?
    @State private var banner: (ok: Bool, title: String, detail: String)?
    @State private var error: String?

    private var dlcExpired: Bool { Calendar.current.startOfDay(for: dlc) < Calendar.current.startOfDay(for: Date()) }
    private var missing: [String] {
        var m: [String] = []
        if product.trimmingCharacters(in: .whitespaces).isEmpty { m.append("produit") }
        if supplier.trimmingCharacters(in: .whitespaces).isEmpty { m.append("fournisseur") }
        return m
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let banner { ResultBanner(ok: banner.ok, title: banner.title, detail: banner.detail) }

                PhotoCapture(photo: $photo, photoData: $photoData, color: .brown)

                Field(title: "Produit", text: $product, placeholder: "ex. poulet, morue, farine…",
                      suggestions: store.recentValues(kind: "reception", key: "product"))
                Field(title: "Fournisseur", text: $supplier, placeholder: "ex. Antilles Frais",
                      suggestions: store.recentValues(kind: "reception", key: "supplier"))
                Field(title: "N° de lot", text: $lot, placeholder: "sur l'étiquette", suggestions: [])

                VStack(alignment: .leading, spacing: 10) {
                    Text("DLC / DDM").font(.headline)
                    HStack(spacing: 10) {
                        ForEach([1, 3, 7, 30], id: \.self) { d in
                            ChipButton(title: "J+\(d)", selected: false, color: .brown) {
                                dlc = Calendar.current.date(byAdding: .day, value: d, to: Date())!
                            }
                        }
                        DatePicker("", selection: $dlc, displayedComponents: .date)
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "fr_FR"))
                            .scaleEffect(1.2)
                            .padding(.leading, 12)
                    }
                    if dlcExpired {
                        Label("DLC dépassée : refuser la marchandise (et déclarer un incident).",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.headline).foregroundStyle(Theme.alert)
                    }
                }

                if let error { Text(error).foregroundStyle(Theme.alert) }

            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Réception (autres produits)")
        .safeAreaInset(edge: .bottom) {
            SaveBar(title: "Enregistrer la réception", systemImage: "square.and.arrow.down.fill",
                    color: .brown, missing: missing) { save() }
        }
    }

    private func save() {
        error = nil
        var sha: String?
        if let data = photoData {
            do { sha = try store.savePhoto(data) } catch {
                self.error = "Photo non enregistrée : \(error.localizedDescription)"
                return
            }
        }
        let p = product.trimmingCharacters(in: .whitespaces)
        let s = supplier.trimmingCharacters(in: .whitespaces)
        store.recordReception(supplier: s, lot: lot.trimmingCharacters(in: .whitespaces),
                              dlc: Fmt.isoDay.string(from: dlc), product: p, photoSHA256: sha)
        banner = (!dlcExpired, "Réception scellée : \(p)",
                  "\(s) — DLC \(Fmt.day(dlc))\(sha != nil ? " — photo liée" : " — sans photo")")
        dlcExpired ? Haptics.warning() : Haptics.success()
        product = ""; lot = ""; photo = nil; photoData = nil
    }
}

/// Photo d'étiquette : appareil photo (si présent) ou photothèque.
struct PhotoCapture: View {
    @Binding var photo: UIImage?
    @Binding var photoData: Data?
    var color: Color = .brown

    @State private var showCamera = false
    @State private var libraryItem: PhotosPickerItem?

    var body: some View {
        HStack(spacing: 18) {
            Group {
                if let photo {
                    Image(uiImage: photo).resizable().scaledToFill()
                } else {
                    Image(systemName: "photo.badge.plus").font(.system(size: 44)).foregroundStyle(.secondary)
                }
            }
            .frame(width: 150, height: 150)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 12) {
                Text("Photo de l'étiquette").font(.headline)
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button { showCamera = true } label: {
                        Label("Prendre la photo", systemImage: "camera.fill")
                    }
                    .buttonStyle(BigButtonStyle(color: color))
                    .frame(maxWidth: 320)
                }
                PhotosPicker(selection: $libraryItem, matching: .images) {
                    Label("Choisir dans la photothèque", systemImage: "photo.on.rectangle")
                        .font(.headline)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                if let image { setPhoto(image) }
                showCamera = false
            }
            .ignoresSafeArea()
        }
        .task(id: libraryItem) {
            guard let item = libraryItem,
                  let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
            setPhoto(image)
        }
        // Photo effacée par l'écran parent (après enregistrement) : on oublie la sélection.
        .onChange(of: photo == nil) { isNil in if isNil { libraryItem = nil } }
    }

    private func setPhoto(_ image: UIImage) {
        photo = image
        photoData = image.jpegData(compressionQuality: 0.7)
    }
}

/// Champ texte large avec suggestions (valeurs déjà saisies) en un tap.
struct Field: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let suggestions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !title.isEmpty { Text(title).font(.headline) }
            TextField(placeholder, text: $text)
                .font(.title3)
                .padding(14)
                .inputBox()
            if !suggestions.isEmpty {
                FlowLayout {
                    ForEach(suggestions, id: \.self) { s in
                        ChipButton(title: s, selected: s == text) { text = s }
                    }
                }
            }
        }
    }
}

/// Appareil photo (UIKit) exposé à SwiftUI.
struct CameraPicker: UIViewControllerRepresentable {
    let onFinish: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onFinish: (UIImage?) -> Void
        init(onFinish: @escaping (UIImage?) -> Void) { self.onFinish = onFinish }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onFinish(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { onFinish(nil) }
    }
}
