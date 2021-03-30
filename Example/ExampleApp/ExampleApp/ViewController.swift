//
//  ViewController.swift
//  ExampleApp
//
//  Created by Ilya Senchukov on 30.03.2021.
//

import UIKit
import ImageLoader

class ViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView?

    let imageLoader = ImageLoader()

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        collectionView?.register(UINib(nibName: "ImageCell", bundle: nil), forCellWithReuseIdentifier: "ImageCell")
    }


}

extension ViewController: UICollectionViewDelegateFlowLayout {

}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        20
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCell else {
            fatalError()
        }

        cell.image = imageLoader.image
    }

    
}

