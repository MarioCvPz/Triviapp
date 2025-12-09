//
//  QuestionCollectionViewCell.swift
//  Triviapp
//
//  Created by Mananas on 5/12/25.
//

import UIKit

class QuestionCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var categoryImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Asegura que la imagen no deforma la celda
        categoryImage.contentMode = .scaleAspectFit
        categoryImage.clipsToBounds = true
    }
}
