import SwiftUI
import WebKit

struct WebView: View {
    let url: URL
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var isLoading = true
    @State private var title: String = "Get Your Guide"
    
    var body: some View {
        NavigationView {
            ZStack {
                StableWebView(url: url, isLoading: $isLoading, title: $title)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .navigationBarTitle(title, displayMode: .inline)
            .navigationBarItems(trailing: Button(languageManager.localize("done")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#if os(iOS)
struct StableWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var title: String
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: StableWebView
        private var loadingStartedTime: Date?
        private var hasCompletedInitialLoad = false
        
        init(_ parent: StableWebView) {
            self.parent = parent
            super.init()
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            if !hasCompletedInitialLoad {
                loadingStartedTime = Date()
                parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            hasCompletedInitialLoad = true
            parent.isLoading = false
            
            if let pageTitle = webView.title, !pageTitle.isEmpty {
                parent.title = pageTitle
            }
            
            if let startTime = loadingStartedTime {
                let loadTime = Date().timeIntervalSince(startTime)
                print("🌐 WebView loaded in \(loadTime) seconds")
                loadingStartedTime = nil
            }
            
            let script = """
                var style = document.createElement('style');
                style.innerHTML = 'body { -webkit-user-select: none; -webkit-touch-callout: none; }';
                document.head.appendChild(style);
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            print("🔴 WebView navigation error: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            print("🔴 WebView provisional navigation error: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            
            if url.host?.contains("getyourguide") == true {
                decisionHandler(.allow)
                return
            }
            
            if navigationAction.navigationType == .linkActivated {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
    }
}
#else
struct StableWebView: NSViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var title: String
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        webView.load(request)
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: StableWebView
        private var loadingStartedTime: Date?
        private var hasCompletedInitialLoad = false
        
        init(_ parent: StableWebView) {
            self.parent = parent
            super.init()
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            if !hasCompletedInitialLoad {
                loadingStartedTime = Date()
                parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            hasCompletedInitialLoad = true
            parent.isLoading = false
            
            if let pageTitle = webView.title, !pageTitle.isEmpty {
                parent.title = pageTitle
            }
            
            if let startTime = loadingStartedTime {
                let loadTime = Date().timeIntervalSince(startTime)
                print("🌐 WebView loaded in \(loadTime) seconds")
                loadingStartedTime = nil
            }
            
            let script = """
                var style = document.createElement('style');
                style.innerHTML = 'body { -webkit-user-select: none; -webkit-touch-callout: none; }';
                document.head.appendChild(style);
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            print("🔴 WebView navigation error: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            print("🔴 WebView provisional navigation error: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            
            if url.host?.contains("getyourguide") == true {
                decisionHandler(.allow)
                return
            }
            
            if navigationAction.navigationType == .linkActivated {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
    }
}
#endif