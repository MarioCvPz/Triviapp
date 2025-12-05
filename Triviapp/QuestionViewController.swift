//
//  QuestionViewController.swift
//  Triviapp
//
//  Created by Mananas on 5/12/25.
//

import UIKit

class QuestionViewController: UIViewController {

    @IBOutlet weak var preguntaAcertadaButton: UIButton!
    @IBOutlet weak var categoryLabel: UILabel!

    // Property to receive the selected category from DiceViewController
    var category: String?

    // Índice de la categoría en el collection view (0..5)
    var categoryIndex: Int?

    // Closure para notificar que se ha acertado la pregunta de esta categoría
    var onAnsweredCorrectly: ((Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true

        if let categoryLabel = categoryLabel {
            categoryLabel.text = category ?? "Sin categoría"
        } else {
            print("Categoría recibida: \(category ?? "nil")")
        }

        // Conectar acción del botón si no está conectada por IB
        preguntaAcertadaButton?.addTarget(self, action: #selector(preguntaAcertadaTapped), for: .touchUpInside)
    }

    @objc private func preguntaAcertadaTapped() {
        if let idx = categoryIndex {
            onAnsweredCorrectly?(idx)
        }
        // Volver a DiceViewController (estás en un Navigation Controller)
        navigationController?.popViewController(animated: true)
    }

    /*
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // No preparamos nada aquí
    }
    */

}
