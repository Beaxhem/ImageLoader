import UIKit
import NetworkManagement
import EventUpdater

public class ImageLoader {

    private let cache = ImageCache()

    var dynamic: Bool

    var networkManager: NetworkManager?

    var updateInterval: TimeInterval

    lazy var imageUpdater = ImageUpdater(networkManager: networkManager, updateInterval: updateInterval, cache: cache)

    public init(networkManager: NetworkManager? = nil, dynamic: Bool = false, updateInterval: TimeInterval = 10) {
        self.networkManager = networkManager
        self.dynamic = dynamic
        self.updateInterval = updateInterval

        if dynamic {
            imageUpdater.startUpdating()
        }
    }

    deinit {
        imageUpdater.stopUpdating()
    }

    public func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
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

public final class ImageCache {

    private lazy var imageCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()

        cache.countLimit = config.countLimit

        return cache
    }()

    var urls: Set<URL> = []

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

        if self.image(for: url) != nil {
            removeFromCache(url: url)
        }

        lock.lock(); defer { lock.unlock() }
        urls.insert(url)
        imageCache.setObject(decodedImage, forKey: url as AnyObject)
    }

    func image(for url: URL) -> UIImage? {
        lock.lock(); defer { lock.unlock() }

        if let image = imageCache.object(forKey: url as AnyObject) {
            return image as? UIImage
        }

        return nil
    }

    func removeFromCache(url: URL) {
        imageCache.removeObject(forKey: url as AnyObject)
    }
}

class ImageUpdater: EventUpdater {

    var timer: DispatchSourceTimer?

    var deadline: DispatchTime?

    var timeInterval: TimeInterval

    var networkManager: NetworkManager?

    var cache: ImageCache

    init(networkManager: NetworkManager? = nil, updateInterval: TimeInterval, cache: ImageCache) {
        self.networkManager = networkManager
        self.timeInterval = updateInterval
        self.cache = cache
    }

    func eventHandler() {
        for url in cache.urls {
            networkManager?.dataTask(url: url, completion: { [weak self] (res: Result<Data, NetworkError>) in
                guard let self = self else {
                    return
                }

                switch res {
                    case .success(let newData):
                        guard let oldData = self.cache.image(for: url)?.pngData() else {
                            return
                        }

                        if newData != oldData {
                            guard let newImage = UIImage(data: newData) else {
                                return
                            }

                            self.cache.insertImage(image: newImage, for: url)
                            print("updated image")
                        } else {
                            print("received equal images")
                        }
                    case .failure(let error):
                        print(error)
                }
            })
        }
    }
}
