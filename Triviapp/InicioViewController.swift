//
//  ViewController.swift
//  Triviapp
//
//  Created by Mananas on 5/12/25.
//

import UIKit

class InicioViewController: UIViewController {

    @IBOutlet weak var inicioButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "StartGame" {
            // Si necesitas pasar datos al DiceViewController, haz el cast aquí.
            // let destination = segue.destination as? DiceViewController
            // destination?.someProperty = value
        }
    }
}
