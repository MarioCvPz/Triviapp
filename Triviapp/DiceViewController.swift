//
//  DiceViewController.swift
//  Triviapp
//

import UIKit
import SceneKit

class DiceViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var diceScene: SCNView!
    @IBOutlet weak var girarButton: UIButton!

    // Collection de quesitos
    @IBOutlet weak var QuesitosCollectionView: UICollectionView!

    var diceNode: SCNNode!
    var sheetView: UIView!
    var sheetImageView: UIImageView!
    var continueButton: UIButton!
    var categoryLabel: UILabel!

    var currentCategory: String?

    private var materialIndexToFaceNumber: [Int] = [1, 2, 3, 4, 5, 6]
    private var selectedFaceNumber: Int?

    let categories: [(image: String, name: String)] = [
        ("dice1", "Geografía"),
        ("dice2", "Arte y Literatura"),
        ("dice3", "Historia"),
        ("dice4", "Entretenimiento"),
        ("dice5", "Ciencias y Naturaleza"),
        ("dice6", "Deportes y Pasatiempos")
    ]

    var completedCategories = Set<Int>()
    var selectedCategoryIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()

        QuesitosCollectionView.dataSource = self
        QuesitosCollectionView.delegate = self
        QuesitosCollectionView.isScrollEnabled = false

        // Layout fijo: 3x2 con celdas 65x65
        if let flow = QuesitosCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.estimatedItemSize = .zero
            flow.minimumInteritemSpacing = 12
            flow.minimumLineSpacing = 12
            flow.sectionInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        }

        setupScene()
        setupBottomSheet()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        QuesitosCollectionView.collectionViewLayout.invalidateLayout()
    }

    @IBAction func girarButtonTapped(_ sender: UIButton) {
        hideCategorySheet()

        let available = (0..<categories.count).filter { !completedCategories.contains($0) }
        guard let chosenIndex = available.randomElement() else {
            showWinSheet()
            return
        }

        selectedCategoryIndex = chosenIndex
        let face = chosenIndex + 1
        selectedFaceNumber = face

        rollDice(toFace: face)
    }

    func setupScene() {
        let scene = SCNScene()
        diceScene.scene = scene
        diceScene.backgroundColor = .white
        diceScene.autoenablesDefaultLighting = false

        // Cámara ajustada para ver el dado centrado en y=0
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 1.8, 4.8)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        // Luz ambiental y direccional para mejorar visibilidad
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 600
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let directional = SCNLight()
        directional.type = .directional
        directional.intensity = 800
        let directionalNode = SCNNode()
        directionalNode.light = directional
        directionalNode.eulerAngles = SCNVector3(-Float.pi/3, Float.pi/6, 0.0)
        scene.rootNode.addChildNode(directionalNode)

        // Suelo
        let floor = SCNFloor()
        floor.reflectivity = 0
        floor.firstMaterial?.diffuse.contents = UIColor.white

        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, -1, 0)
        floorNode.physicsBody = SCNPhysicsBody.static()
        scene.rootNode.addChildNode(floorNode)

        scene.physicsWorld.gravity = SCNVector3(0, -9.8, 0)

        createDice(on: scene)
    }

    // Inclinación suave para que la cara superior sea más visible
    private let initialTilt = SCNVector3(-0.21, 0.17, 0.0) // ~ -12° en X, +10° en Y

    func createDice(on scene: SCNScene) {
        // Dado 15% más pequeño que el original (2.8 -> 2.38, 0.4 -> 0.34)
        let box = SCNBox(width: 2.38, height: 2.38, length: 2.38, chamferRadius: 0.34)
        box.materials = createDiceMaterials()

        diceNode = SCNNode(geometry: box)

        // Colocar el dado centrado y sin animación de caída
        diceNode.position = SCNVector3(0, 0, 0)
        diceNode.eulerAngles = initialTilt

        // Usar cuerpo cinemático para que no le afecte la gravedad (no cae)
        let body = SCNPhysicsBody.kinematic()
        body.isAffectedByGravity = false
        diceNode.physicsBody = body

        scene.rootNode.addChildNode(diceNode)
    }

    func createDiceMaterials() -> [SCNMaterial] {
        let front = SCNMaterial()
        front.diffuse.contents = UIImage(named: "dice1")
        let right = SCNMaterial()
        right.diffuse.contents = UIImage(named: "dice2")
        let back = SCNMaterial()
        back.diffuse.contents = UIImage(named: "dice3")
        let left = SCNMaterial()
        left.diffuse.contents = UIImage(named: "dice4")
        let top = SCNMaterial()
        top.diffuse.contents = UIImage(named: "dice5")
        let bottom = SCNMaterial()
        bottom.diffuse.contents = UIImage(named: "dice6")
        return [front, right, back, left, top, bottom]
    }

    private func faceNumberToTargetEulerAngles(_ number: Int) -> SCNVector3 {
        switch number {
        case 1: return SCNVector3(-Float.pi/2, 0, 0)
        case 2: return SCNVector3(0, 0,  Float.pi/2)
        case 3: return SCNVector3( Float.pi/2, 0, 0)
        case 4: return SCNVector3(0, 0, -Float.pi/2)
        case 5: return SCNVector3(0, 0, 0)
        case 6: return SCNVector3( Float.pi, 0, 0)
        default: return SCNVector3(0, 0, 0)
        }
    }

    private func rollDice(toFace faceNumber: Int) {
        guard let body = diceNode.physicsBody else { return }

        // Mantenerlo sin física de caída durante el giro
        body.clearAllForces()
        body.velocity = SCNVector3Zero
        body.angularVelocity = SCNVector4Zero
        body.isAffectedByGravity = false
        body.type = .kinematic

        // Reposicionarlo al centro antes de animar
        diceNode.position = SCNVector3(0, 0, 0)
        diceNode.eulerAngles = SCNVector3Zero

        let spinDuration: TimeInterval = 0.6
        let settleDuration: TimeInterval = 1

        let randomTurnsX = Float.random(in: 1.5...2.5) * 2 * Float.pi
        let randomTurnsY = Float.random(in: 1.5...2.5) * 2 * Float.pi
        let randomTurnsZ = Float.random(in: 1.0...2.0) * 2 * Float.pi
        let spinAngles = SCNVector3(randomTurnsX, randomTurnsY, randomTurnsZ)

        let spinAction = SCNAction.rotateTo(
            x: CGFloat(spinAngles.x),
            y: CGFloat(spinAngles.y),
            z: CGFloat(spinAngles.z),
            duration: spinDuration,
            usesShortestUnitArc: false
        )

        // Orientación exacta para que "esa cara" quede arriba
        let target = faceNumberToTargetEulerAngles(faceNumber)

        // Pequeña inclinación final para hacer la cara superior más visible
        let finalWithTilt = SCNVector3(target.x + initialTilt.x,
                                       target.y + initialTilt.y,
                                       target.z + initialTilt.z)

        let settleAction = SCNAction.rotateTo(
            x: CGFloat(finalWithTilt.x),
            y: CGFloat(finalWithTilt.y),
            z: CGFloat(finalWithTilt.z),
            duration: settleDuration,
            usesShortestUnitArc: true
        )

        let sequence = SCNAction.sequence([spinAction, settleAction])

        diceNode.runAction(sequence) { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.showCategorySheet(faceNumber)
            }
        }
    }

    func setupBottomSheet() {
        let width = view.frame.width
        let height = view.frame.height * 0.75

        sheetView = UIView(frame: CGRect(x: 0, y: view.frame.height, width: width, height: height))

        if #available(iOS 13.0, *) {
            sheetView.backgroundColor = .systemGray6
        } else {
            sheetView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        }

        sheetView.layer.cornerRadius = 22
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.layer.shadowColor = UIColor.black.cgColor
        sheetView.layer.shadowOpacity = 0.15
        sheetView.layer.shadowOffset = CGSize(width: 0, height: -2)
        sheetView.layer.shadowRadius = 10
        sheetView.layer.masksToBounds = false

        categoryLabel = UILabel(frame: CGRect(x: 20, y: 20, width: width - 40, height: 35))
        categoryLabel.textAlignment = .center
        categoryLabel.font = UIFont.boldSystemFont(ofSize: 28)
        sheetView.addSubview(categoryLabel)

        sheetImageView = UIImageView(frame: CGRect(x: 20, y: categoryLabel.frame.maxY + 20, width: width - 40, height: height - 180))
        sheetImageView.contentMode = .scaleAspectFit
        sheetView.addSubview(sheetImageView)

        continueButton = UIButton(type: .system)
        continueButton.frame = CGRect(x: 40, y: height - 80, width: width - 80, height: 50)
        continueButton.setTitle("Continuar", for: .normal)
        continueButton.backgroundColor = .systemBlue
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 12
        continueButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        sheetView.addSubview(continueButton)

        view.addSubview(sheetView)
    }

    func showCategorySheet(_ number: Int) {
        let idx = max(0, min(categories.count - 1, number - 1))
        let category = categories[idx]

        currentCategory = category.name
        categoryLabel.text = category.name
        sheetImageView.image = UIImage(named: category.image)
        sheetImageView.tintColor = nil

        continueButton.setTitle("Continuar", for: .normal)
        continueButton.removeTarget(nil, action: nil, for: .allEvents)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)

        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.4, options: [.curveEaseOut]) {
            self.sheetView.frame.origin.y = self.view.frame.height - self.sheetView.frame.height
        }
    }

    func hideCategorySheet(animated: Bool = true, completion: (() -> Void)? = nil) {
        let hideBlock = { self.sheetView.frame.origin.y = self.view.frame.height }
        if animated {
            UIView.animate(withDuration: 0.3, animations: hideBlock) { _ in completion?() }
        } else {
            hideBlock()
            completion?()
        }
    }

    @objc func continueButtonTapped() {
        hideCategorySheet { [weak self] in
            self?.performSegue(withIdentifier: "goToQuestions", sender: self)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToQuestions" {
            let pass: (QuestionViewController) -> Void = { qvc in
                qvc.category = self.currentCategory
                qvc.categoryIndex = self.selectedCategoryIndex
                qvc.onAnsweredCorrectly = { [weak self] index in
                    guard let self = self else { return }
                    self.completedCategories.insert(index)
                    let ip = IndexPath(item: index, section: 0)
                    self.QuesitosCollectionView.reloadItems(at: [ip])
                    if self.completedCategories.count == self.categories.count {
                        self.showWinSheet()
                    }
                }
            }
            if let destination = segue.destination as? QuestionViewController {
                pass(destination)
            } else if let nav = segue.destination as? UINavigationController,
                      let top = nav.topViewController as? QuestionViewController {
                pass(top)
            }
        }
    }

    func showWinSheet() {
        currentCategory = nil
        categoryLabel.text = "HAS GANADO"
        sheetImageView.image = UIImage(systemName: "trophy.fill")
        sheetImageView.tintColor = .systemYellow

        continueButton.setTitle("Volver a jugar", for: .normal)
        continueButton.removeTarget(nil, action: nil, for: .allEvents)
        continueButton.addTarget(self, action: #selector(restartGameTapped), for: .touchUpInside)

        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.4, options: [.curveEaseOut]) {
            self.sheetView.frame.origin.y = self.view.frame.height - self.sheetView.frame.height
        }
    }

    @objc func restartGameTapped() {
        completedCategories.removeAll()
        QuesitosCollectionView.reloadData()

        continueButton.setTitle("Continuar", for: .normal)
        continueButton.removeTarget(nil, action: nil, for: .allEvents)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)

        hideCategorySheet()
    }

    // MARK: - UICollectionView DataSource/Delegate

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QuestionCollectionViewCell", for: indexPath) as! QuestionCollectionViewCell

        let item = categories[indexPath.item]
        cell.categoryImage.contentMode = .scaleAspectFit
        cell.categoryImage.image = UIImage(named: item.image)

        let starTag = 1003
        let isCompleted = completedCategories.contains(indexPath.item)
        if let starView = cell.contentView.viewWithTag(starTag) as? UIImageView {
            starView.isHidden = !isCompleted
        } else {
            let starView = UIImageView(image: UIImage(systemName: "star.fill"))
            starView.tag = starTag
            starView.tintColor = .systemYellow
            starView.contentMode = .scaleAspectFit
            starView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(starView)
            NSLayoutConstraint.activate([
                starView.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                starView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6),
                starView.heightAnchor.constraint(equalToConstant: 20),
                starView.widthAnchor.constraint(equalTo: starView.heightAnchor)
            ])
            starView.isHidden = !isCompleted
        }

        return cell
    }

    // 3 columnas exactas x 2 filas (celdas cuadradas). Ajusta insets/spacing arriba si quieres más/menos tamaño.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 3
        let insets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        let interitem: CGFloat = 12

        let totalHorizontalSpacing = insets.left + insets.right + interitem * (columns - 1)
        let availableWidth = collectionView.bounds.width - totalHorizontalSpacing
        let cellWidth = floor(availableWidth / columns)
        return CGSize(width: cellWidth, height: cellWidth)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
}
