//
//  ViewController.swift
//  ExampleApp
//
//  Created by Ilya Senchukov on 30.03.2021.
//

import UIKit
import ImageLoader
import NetworkManagement

class ViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView?

    lazy var imageLoader = ImageLoader(networkManager: networkManager)

    let networkManager = NetworkManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        collectionView?.register(UINib(nibName: "ImageCell", bundle: nil), forCellWithReuseIdentifier: "ImageCell")
    }


}

extension ViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 200)
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        20
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCell else {
            fatalError()
        }

        guard let url = URL(string: "https://picsum.photos/200/300") else {
            fatalError()
        }

        imageLoader.loadImage(from: url) { image in
            DispatchQueue.main.async {
                cell.image = image
            }
        }

        return cell
    }

    
}

class ImageCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView?

    var image: UIImage? {
        didSet {
            imageView?.image = image
        }
    }
}
