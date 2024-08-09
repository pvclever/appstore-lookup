# App Store Lookup
This is a snippet showing how to fetch the App details from the App Store

## How it works
The service requests data on: https://itunes.apple.com/lookup
And then parses the respons using swift Decodable protocol

## Usage:

**Async Style**
```swift
do {
    let storeUrl = await AppStoreLookupService.shared.getStoreUrl(bundleId: bundleId)
    print(storeUrl)
} catch {
    print(error)
}
```

**Closure Style**
```swift
AppStoreLookupService.shared.getStoreUrl(bundleId: bundleId) { result in
    switch result {
    case .success(let storeUrl)
        print(storeUrl)
    case .failure(let error):
        print(error)
    }
}
```