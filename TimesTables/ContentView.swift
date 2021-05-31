//
//  ContentView.swift
//  TimesTables
//
//  Created by David Bailey on 31/05/2021.
//

import SwiftUI

enum QuestionAmount: String, CaseIterable, Identifiable {
    case five = "5"
    case ten = "10"
    case twenty = "20"
    case all = "All"

    var id: String { rawValue }
}

struct Question {
    var multiplicand: Int
    var multiplier: Int
}

struct ContentView: View {
    @State private var timesTable = 2
    @State private var maxMultiplier = 10
    @State private var questionAmount = QuestionAmount.ten
    @State private var randomOrder = true
    @State private var questions: [Question]? = nil

    var body: some View {
        NavigationView {
            if questions == nil {
                SettingsForm(
                    timesTable: $timesTable,
                    maxMultiplier: $maxMultiplier,
                    questionAmount: $questionAmount,
                    randomOrder: $randomOrder,
                    questions: $questions
                )
            } else {
                GameView(questions: questions!, exit: exit)
            }
        }
    }

    func exit() {
        questions = nil
    }
}

struct SettingsForm: View {
    @Binding var timesTable: Int
    @Binding var maxMultiplier: Int
    @Binding var questionAmount: QuestionAmount
    @Binding var randomOrder: Bool
    @Binding var questions: [Question]?

    var body: some View {
        Form {
            Section(header: Text("Game settings")) {
                Stepper(value: $timesTable, in: 2 ... 12) {
                    Text("\(timesTable) times table")
                }

                Stepper(value: $maxMultiplier, in: 3 ... 12) {
                    Text("Up to \(timesTable) × \(maxMultiplier)")
                }

                HStack {
                    Text("Questions")
                    Spacer()
                    Picker("Questions", selection: $questionAmount) {
                        ForEach(QuestionAmount.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 184)
                }

                if questionAmount == .all {
                    Toggle("Random order", isOn: $randomOrder)
                }
            }

            Button(action: {
                switch questionAmount {
                case .five:
                    generateRandomQuestions(5)
                case .ten:
                    generateRandomQuestions(10)
                case .twenty:
                    generateRandomQuestions(20)
                case .all:
                    generateAllQuestions()
                }
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Start game")
                }
            }
        }
        .navigationTitle("Times Tables")
    }

    func generateRandomQuestions(_ amount: Int) {
        questions = (1 ... amount).map { _ in
            Question(
                multiplicand: timesTable,
                multiplier: Int.random(in: 2 ... maxMultiplier)
            )
        }
    }

    func generateAllQuestions() {
        let questions = (2 ... maxMultiplier).map { multiplier in
            Question(multiplicand: timesTable, multiplier: multiplier)
        }

        if randomOrder {
            self.questions = questions.shuffled()
        } else {
            self.questions = questions
        }
    }
}

func getAllAnswers() -> Set<Int> {
    var answers = [Int]()

    for i in 2 ... 12 {
        for j in 2 ... 12 {
            answers.append(i * j)
        }
    }

    return Set(answers)
}

enum Effect {
    case correct
    case fadeOut
}

enum Answer: Identifiable {
    case number(value: Int, effect: Effect? = nil)
    case animal(id: String, effect: Effect? = nil)

    var id: String {
        switch self {
        case .number(let value, _): return "\(value)"
        case .animal(let id, _): return id
        }
    }

    mutating func applyEffect(_ effect: Effect) {
        switch self {
        case .number(let value, _):
            self = .number(value: value, effect: effect)
        case .animal(let id, _):
            self = .animal(id: id, effect: effect)
        }
    }
}

let animals = [
    "bear", "buffalo", "chick", "chicken", "cow", "crocodile", "dog", "duck",
    "elephant", "frog", "giraffe", "goat", "gorilla", "hippo", "horse",
    "monkey", "moose", "narwhal", "owl", "panda", "parrot", "penguin", "pig",
    "rabbit", "rhino", "sloth", "snake", "walrus", "whale", "zebra"
]

struct GameView: View {
    var questions: [Question]
    var exit: () -> Void

    @State private var score = 0
    @State private var questionNumber = 0
    @State private var answers = [Answer]()
    @State private var flipped = Bool.random()

    private var question: Question { questions[questionNumber] }
    private var answer: Int { question.multiplicand * question.multiplier }

    let columns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(answers) { answer in
                    switch answer {
                    case .number(let value, let effect):
                        AnswerButton(
                            answer: value,
                            effect: effect,
                            action: answerTapped
                        )
                    case .animal(let id, let effect):
                        AnimalBlock(animal: id, effect: effect)
                    }
                }
                .animation(.spring())
            }

            Spacer()

            HStack(alignment: .bottom) {
                Text("Score: \(score)")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Text(
                    "Question \(questionNumber + 1) of \(questions.count)"
                )
                .fontWeight(.bold)
            }
        }
        .navigationTitle(
            flipped ?
                "\(question.multiplier) × \(question.multiplicand) =" :
                "\(question.multiplicand) × \(question.multiplier) ="
        )
        .navigationBarItems(
            leading: Button(action: exit) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.backward")
                    Text("Back")
                        .fontWeight(.regular)
                }
            }
        )
        .padding()
        .onAppear(perform: generateAnswers)
    }

    func generateAnswers() {
        // shuffle + remove correct answer
        let allAnswers = getAllAnswers()
            .shuffled()
            .filter { $0 != answer }

        let animals = animals.shuffled()

        // correct answer + 9 other answers + 6 animals
        answers = (
            [.number(value: answer)] +
                allAnswers[..<9].map { .number(value: $0) } +
                animals[..<6].map { .animal(id: $0) }
        ).shuffled()
    }

    func answerTapped(_ answer: Int) {
        if answer == self.answer {
            for i in 0 ..< answers.count {
                switch answers[i] {
                case .number(let value, _):
                    if value == answer {
                        answers[i].applyEffect(.correct)
                    } else {
                        answers[i].applyEffect(.fadeOut)
                    }
                case .animal:
                    answers[i].applyEffect(.fadeOut)
                }
            }

            score += 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            if questionNumber >= (questions.count - 1) {
                exit()
            } else {
                questionNumber += 1
                flipped = Bool.random()
                generateAnswers()
            }
        }
    }
}

enum BlockColor: String, CaseIterable {
    case blue
    case green
    case grey
    case red
    case yellow
}

struct AnswerButton: View {
    let answer: Int
    let effect: Effect?
    let action: (Int) -> Void
    @State private var color = BlockColor.allCases.randomElement()!

    private var textColor: Color {
        switch color {
        case .blue: return .white
        case .green: return .black
        case .grey: return .black
        case .red: return .white
        case .yellow: return .black
        }
    }

    var body: some View {
        Button(action: { action(answer) }) {
            ZStack {
                Image("\(color.rawValue)_button")
                    .renderingMode(.original)
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(1, contentMode: .fill)
                Text("\(answer)")
                    .font(.system(size: 30))
                    .fontWeight(.black)
                    .foregroundColor(textColor)
                    .offset(y: -2)
            }
        }
        .opacity(effect == .fadeOut ? 0.25 : 1)
        .rotation3DEffect(
            .degrees(effect == .correct ? 360 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .scaleEffect(effect == .correct ? 1.5 : 1)
        .zIndex(effect == .correct ? 1 : 0)
    }
}

struct AnimalBlock: View {
    let animal: String
    let effect: Effect?

    var body: some View {
        Image(animal)
            .resizable()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .opacity(effect == .fadeOut ? 0.5 : 1)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
