import SwiftUI
import PhotosUI

struct DraftIngredient: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var amount: String
}

struct CreateRecipeView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 1
    @State private var title = ""
    @State private var timeText = ""
    @State private var servingsText = ""
    @State private var cuisine = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var ingredients: [DraftIngredient] = []
    @State private var stepDescriptions: [String] = []
    @State private var showAddIngredient = false
    @State private var showAddStep = false
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""

    @FocusState private var titleFocused: Bool

    private var step1Incomplete: Bool {
        currentStep == 1 && (title.trimmingCharacters(in: .whitespaces).isEmpty || imageData == nil)
    }

    var body: some View {
        ZStack {
            Theme.Palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        progressBar
                        dishNameRow

                        if currentStep == 1 {
                            step1Content
                        } else if currentStep == 2 {
                            step2Content
                        } else {
                            step3Content
                        }

                        actionRow
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    imageData = data
                }
            }
        }
        .sheet(isPresented: $showAddIngredient) {
            AddIngredientSheet { name, amount in
                ingredients.append(DraftIngredient(name: name, amount: amount))
            }
            .presentationDetents([.height(464)])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showAddStep) {
            AddStepSheet(stepNumber: stepDescriptions.count + 1) { desc in
                stepDescriptions.append(desc)
            }
            .presentationDetents([.height(432)])
            .presentationDragIndicator(.hidden)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            BackButton {
                if currentStep > 1 { currentStep -= 1 } else { dismiss() }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 8)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        StepProgressBar(currentStep: currentStep, totalSteps: 3)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Dish Name Row

    private var dishNameRow: some View {
        TextField(
            "",
            text: $title,
            prompt: Text("Recipe name").foregroundColor(Theme.Palette.darkBrown.opacity(0.4))
        )
        .font(Theme.Typography.title)
        .foregroundStyle(Theme.Palette.darkBrown)
        .tint(Theme.Palette.lightBrown)
        .focused($titleFocused)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Step 1: Basic Info

    @ViewBuilder
    private var step1Content: some View {
        imagePickerArea

        VStack(spacing: 20) {
            inputField(label: "Estimate time to make (minutes)", placeholder: "Enter a number...", text: $timeText, keyboard: .numberPad)
            inputField(label: "Servings", placeholder: "Enter a number...", text: $servingsText, keyboard: .numberPad)
            inputField(label: "Cuisine", placeholder: "Begin typing a cuisine...", text: $cuisine, keyboard: .default)
        }
    }

    @ViewBuilder
    private var imagePickerArea: some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity, maxHeight: 264)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        } else {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "EFEFEF"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 264)

                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 32))
                            .foregroundColor(Theme.Palette.lightBrown.opacity(0.7))
                        Text("Add an image")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.Palette.lightBrown)
                    }
                }
            }
        }
    }

    // MARK: - Step 2: Ingredients

    @ViewBuilder
    private var step2Content: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 72))
                    .foregroundColor(Theme.Palette.darkBrown)
                Text("Ingredient List")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Palette.darkBrown)
                    .padding(.leading, 13)
            }

            VStack(spacing: 20) {
                ForEach(ingredients) { ingredient in
                    HStack {
                        Text(ingredient.name)
                            .font(.system(size: 15))
                            .foregroundColor(Theme.Palette.darkBrown)
                        Spacer()
                        Text(ingredient.amount)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Palette.orangeBrown)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "F6F6F6"))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "A4A4A4"), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                Button { showAddIngredient = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 22))
                        Text("Add Ingredient")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(Theme.Palette.orangeBrown)
                    .padding(10)
                }
            }
        }
    }

    // MARK: - Step 3: Steps

    @ViewBuilder
    private var step3Content: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Palette.darkBrown)
                Text("Steps")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Palette.darkBrown)
            }

            VStack(spacing: 15) {
                ForEach(Array(stepDescriptions.enumerated()), id: \.offset) { index, desc in
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Step \(index + 1)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Palette.orangeBrown)
                        Text(desc)
                            .font(.system(size: 15))
                            .foregroundColor(Theme.Palette.darkBrown)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineSpacing(5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "F6F6F6"))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "A4A4A4"), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                Button { showAddStep = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 22))
                        Text("Add Steps")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(Theme.Palette.orangeBrown)
                    .padding(10)
                }
            }
        }
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack {
            Button { dismiss() } label: {
                Text("Cancel")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "A4A4A4"))
                    .frame(width: 88)
                    .padding(.vertical, 10)
                    .background(Color(hex: "F6F6F6"))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "A4A4A4"), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            Spacer()

            Button {
                if currentStep < 3 { currentStep += 1 }
                else { Task { await submitRecipe() } }
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView().tint(Theme.Palette.cream)
                    } else {
                        Text("Next")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.Palette.cream)
                    }
                }
                .frame(width: 88)
                .padding(.vertical, 10)
                .background(step1Incomplete ? Theme.Palette.darkBrown.opacity(0.4) : Theme.Palette.darkBrown)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .disabled(isSubmitting || step1Incomplete)
        }
        .padding(.top, 10)
    }

    // MARK: - Helpers

    private func inputField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .padding(.leading, 10)

            TextField(placeholder, text: text)
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.black)
                .keyboardType(keyboard)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(height: 35)
                .background(Color(hex: "EFEFEF"))
                .clipShape(Capsule())
        }
    }

    // MARK: - Submission

    private func submitRecipe() async {
        isSubmitting = true
        let timeMinutes = Int(timeText)
        let servings = Int(servingsText)
        let ingredientPayload = ingredients.map { ["name": $0.name, "amount": $0.amount] }

        do {
            _ = try await RecipeService.shared.createRecipe(
                title: title.trimmingCharacters(in: .whitespaces),
                timeMinutes: timeMinutes,
                servings: servings,
                cuisine: cuisine.isEmpty ? nil : cuisine,
                ingredients: ingredientPayload,
                instructions: stepDescriptions,
                imageData: imageData
            )
            dismiss()
        } catch {
            errorMessage = "Failed to create recipe. Please try again."
            showError = true
        }
        isSubmitting = false
    }
}

// MARK: - Add Ingredient Sheet

struct AddIngredientSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (String, String) -> Void

    @State private var ingredientName = ""
    @State private var amount = ""

    var body: some View {
        VStack(spacing: 0) {
            SheetHandle(color: Color(hex: "888888").opacity(0.3))
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 30) {
                Text("Add Ingredient")
                    .font(.system(size: 30))
                    .foregroundColor(Theme.Palette.darkBrown)
                    .padding(.top, 20)

                VStack(spacing: 25) {
                    sheetField("Ingredient Name", placeholder: "Begin typing...", text: $ingredientName)
                    sheetField("Amount", placeholder: "Number and units...", text: $amount)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            HStack {
                Button("Cancel") { dismiss() }
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "A4A4A4"))
                    .frame(width: 88)
                    .padding(.vertical, 10)
                    .background(Color(hex: "F6F6F6"))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "A4A4A4"), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Spacer()

                Button("Add") {
                    guard !ingredientName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onAdd(ingredientName, amount)
                    dismiss()
                }
                .font(.system(size: 15))
                .foregroundColor(Theme.Palette.cream)
                .frame(width: 88)
                .padding(.vertical, 10)
                .background(ingredientName.isEmpty ? Theme.Palette.darkBrown.opacity(0.4) : Theme.Palette.darkBrown)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .disabled(ingredientName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .background(Theme.Palette.background)
    }

    private func sheetField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .padding(.leading, 10)

            TextField(placeholder, text: text)
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(height: 35)
                .background(Color(hex: "EFEFEF"))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Add Step Sheet

struct AddStepSheet: View {
    @Environment(\.dismiss) private var dismiss
    let stepNumber: Int
    let onAdd: (String) -> Void

    @State private var description = ""

    var body: some View {
        VStack(spacing: 0) {
            SheetHandle(color: Color(hex: "888888").opacity(0.3))
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 30) {
                Text("Add Step \(stepNumber)")
                    .font(.system(size: 30))
                    .foregroundColor(Theme.Palette.darkBrown)
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Step Description")
                        .font(.system(size: 15))
                        .foregroundColor(.black)
                        .padding(.leading, 10)

                    TextEditor(text: $description)
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(.black)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .frame(height: 112)
                        .background(Color(hex: "EFEFEF"))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .overlay(
                            Group {
                                if description.isEmpty {
                                    Text("Describe this step...")
                                        .font(.system(size: 15, weight: .light))
                                        .foregroundColor(Color(hex: "888888"))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 18)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            HStack {
                Button("Cancel") { dismiss() }
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "A4A4A4"))
                    .frame(width: 88)
                    .padding(.vertical, 10)
                    .background(Color(hex: "F6F6F6"))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "A4A4A4"), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Spacer()

                Button("Add") {
                    guard !description.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onAdd(description)
                    dismiss()
                }
                .font(.system(size: 15))
                .foregroundColor(Theme.Palette.cream)
                .frame(width: 88)
                .padding(.vertical, 10)
                .background(description.isEmpty ? Theme.Palette.darkBrown.opacity(0.4) : Theme.Palette.darkBrown)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .disabled(description.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .background(Theme.Palette.background)
    }
}
