import UIKit
import NetworkManagement

class ImageLoader {

    private let cache = ImageCache()

    var networkManager: NetworkManager?

    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        if let image = cache.image(for: url) {
            completion(image)
            return
        }

        networkManager?.dataTask(url: url, completion: { [weak self] (res: Result<Data, NetworkError>) in
            switch res {
                case .failure(let error):
                    print(error)
                    completion(nil)
                case .success(let data):
                    guard let image = UIImage(data: data) else {
                        completion(nil)
                        return
                    }
                    self?.cache.insertImage(image: image, for: url)
                    completion(image)
            }
        })
    }
}

final class ImageCache {

    private lazy var imageCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()

        cache.countLimit = config.countLimit

        return cache
    }()

    private let config: Config
    private let lock = NSLock()

    struct Config {

        var countLimit: Int
        let memoryLimit: Int

        static let `default` = Config(countLimit: 100, memoryLimit: 1024 * 1024 * 100)
    }

    init(config: Config = Config.default) {
        self.config = config
    }
}

extension ImageCache {

    func insertImage(image: UIImage, for url: URL) {
        let decodedImage = image.decoded()

        lock.lock(); defer { lock.unlock() }

        imageCache.setObject(decodedImage, forKey: url as AnyObject)
    }

    func image(for url: URL) -> UIImage? {
        lock.lock(); defer { lock.unlock() }

        if let image = imageCache.object(forKey: url as AnyObject) {
            return image as? UIImage
        }

        return nil
    }
}
