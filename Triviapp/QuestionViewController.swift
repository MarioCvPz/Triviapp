//
//  QuestionViewController.swift
//  Triviapp
//
//  Created by Mananas on 5/12/25.
//

import UIKit

class QuestionViewController: UIViewController {

    @IBOutlet weak var answer4: UIButton!
    @IBOutlet weak var answer3: UIButton!
    @IBOutlet weak var answer2: UIButton!
    @IBOutlet weak var answer1: UIButton!
    @IBOutlet weak var questionTextView: UITextView!
    @IBOutlet weak var preguntaAcertadaButton: UIButton!
    @IBOutlet weak var categoryLabel: UILabel!

    // Property to receive the selected category from DiceViewController
    var category: String?

    // Índice de la categoría en el collection view (0..5)
    var categoryIndex: Int?

    // La pregunta a mostrar (inyectada desde DiceViewController)
    var question: Question?

    // Closure para notificar que se ha acertado la pregunta de esta categoría
    var onAnsweredCorrectly: ((Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true

        categoryLabel?.text = category ?? "Sin categoría"
        applyCategoryColor()
        setupUI()
    }

    private func setupUI() {
        // Estilo básico de botones (bordes redondeados y fondo neutro)
        [answer1, answer2, answer3, answer4].forEach { btn in
            btn?.layer.cornerRadius = 10
            btn?.backgroundColor = UIColor.systemGray6
            btn?.setTitleColor(.label, for: .normal)
            btn?.titleLabel?.numberOfLines = 0
            btn?.titleLabel?.textAlignment = .center
            btn?.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            btn?.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
        }

        preguntaAcertadaButton?.isHidden = true // ya no se usa como acción manual

        // Cargar la pregunta
        if let q = question {
            questionTextView?.text = q.text
            let opts = q.options
            answer1?.setTitle(opts[safe: 0]?.text ?? "", for: .normal)
            answer2?.setTitle(opts[safe: 1]?.text ?? "", for: .normal)
            answer3?.setTitle(opts[safe: 2]?.text ?? "", for: .normal)
            answer4?.setTitle(opts[safe: 3]?.text ?? "", for: .normal)
        } else {
            questionTextView?.text = "No hay pregunta disponible."
            [answer1, answer2, answer3, answer4].forEach { $0?.isHidden = true }
        }
    }

    // Aplica color al categoryLabel según el índice de categoría
    private func applyCategoryColor() {
        guard let idx = categoryIndex else { return }
        // Mapa de colores según tu petición:
        // 0 Geografía - azul
        // 1 Arte y Literatura - morado
        // 2 Historia - amarillo
        // 3 Entretenimiento - rosa
        // 4 Ciencias y Naturaleza - verde
        // 5 Deportes y Pasatiempos - naranja
        let color: UIColor
        switch idx {
        case 0: color = .systemBlue
        case 1: color = .systemPurple
        case 2: color = .systemYellow
        case 3:
            if #available(iOS 15.0, *) {
                color = .systemPink
            } else {
                color = UIColor(red: 1.0, green: 0.2, blue: 0.5, alpha: 1.0)
            }
        case 4: color = .systemGreen
        case 5: color = .systemOrange
        default: color = .label
        }
        categoryLabel?.textColor = color
    }

    @objc private func optionTapped(_ sender: UIButton) {
        guard let q = question, let idx = indexForButton(sender) else { return }

        // Evitar taps múltiples
        [answer1, answer2, answer3, answer4].forEach { $0?.isUserInteractionEnabled = false }

        let selectedIsCorrect = q.options[safe: idx]?.isCorrect ?? false

        if selectedIsCorrect {
            sender.backgroundColor = .systemGreen
            // Notificar acierto y volver tras un breve delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self = self else { return }
                if let catIdx = self.categoryIndex {
                    self.onAnsweredCorrectly?(catIdx)
                }
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            sender.backgroundColor = .systemRed
            // Volver sin marcar la estrella
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }

    private func indexForButton(_ button: UIButton) -> Int? {
        switch button {
        case answer1: return 0
        case answer2: return 1
        case answer3: return 2
        case answer4: return 3
        default: return nil
        }
    }
}

// Seguridad de índice para arrays
private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
