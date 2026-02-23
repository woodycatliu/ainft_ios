//
//  WebView.swift
//  ainft_ios
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        webView.backgroundColor = .clear
        webView.isOpaque = false
        
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        private func getRootVC() -> UIViewController? {
            return UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
                .first?.windows
                .first { $0.isKeyWindow }?.rootViewController
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "OK"), style: .default) { _ in
                completionHandler()
            })
            if let rootVC = getRootVC() {
                rootVC.present(alert, animated: true)
            } else {
                completionHandler()
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let tronlinkAction = self.tronlinkAction
            
            guard !tronlinkAction.canPerform(navigationAction) else {
                tronlinkAction.action(navigationAction, decisionHandler: decisionHandler)
                return
            }
            
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            let scheme = url.scheme?.lowercased() ?? ""
            
            // 如果不是網頁標準協議，則嘗試喚起外部 App
            if scheme != "http" && scheme != "https" && scheme != "about" && scheme != "file" {
                
                // 直接嘗試開啟，不使用 canOpenURL (因為可能沒在 Info.plist 宣告)
                UIApplication.shared.open(url, options: [:]) { success in
                    print("[WebView] Open result: \(success)")
                    DispatchQueue.main.async {
                        self.parent.isLoading = false
                    }
                }
                
                // 只要不是 http(s)，就一定要 cancel，避免 WebView 報錯或顯示空白頁
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        
        fileprivate var tronlinkAction: ActionDecision {
            return .init(_canPerform: { navigationAction in
                guard let url = navigationAction.request.url else {
                    return false
                }
                let scheme = url.scheme?.lowercased() ?? ""
                return scheme.contains("tronlinkoutside")
                
            }, _action: { [weak self] navigationAction, decisionHandler in
                guard let url = navigationAction.request.url,
                      let scheme = url.scheme?.lowercased(),
                      scheme.contains("tronlinkoutside") else {
                    decisionHandler(.allow)
                    return
                }
                
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:]) { success in
                        print("[WebView] Open result: \(success)")
                        DispatchQueue.main.async {
                            self?.parent.isLoading = false
                        }
                    }
                } else {
                    let alert = UIAlertController(title: nil, message: String(localized: "Please install TronLink to continue."), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: String(localized: "OK"), style: .default) { _ in
                        UIApplication.shared.open(URL(string: "https://apps.apple.com/us/app/tronlink-trx-btt-wallet/id1453530188")!)
                    })
                    
                    alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .default) { _ in
                       
                    })
                    
                    self?.getRootVC()?.present(alert, animated: true)
                    
                }
                decisionHandler(.cancel)
            })
        }
    }
    
    
    
}


fileprivate struct ActionDecision {
    let _canPerform: (WKNavigationAction) -> Bool
    let _action: (WKNavigationAction, @escaping (WKNavigationActionPolicy) -> Void) -> Void
    
    func canPerform(_ action: WKNavigationAction) -> Bool {
        return _canPerform(action)
    }
    
    func action(_ action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) -> Void {
        _action(action, decisionHandler)
    }
}
