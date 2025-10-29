import Foundation
import IOKit
import os

class PolarService: NSObject {
    private let organizationId = "6b1b7d44-f402-497f-88b0-d3b61c3f378a"
    private let apiToken: String
    private let baseURL = "https://api.polar.sh"
    private let sandboxBaseURL = "https://sandbox-api.polar.sh"
    private let logger = Logger(subsystem: "com.rohitk.Mindmic", category: "PolarService")
    private let isSandbox: Bool

    override init() {
        // Check if we should use sandbox mode
        self.isSandbox = ProcessInfo.processInfo.environment["POLAR_SANDBOX_MODE"] == "true"

        // Get API token from environment variable - no fallback tokens for security
        if let token = ProcessInfo.processInfo.environment["POLAR_ACCESS_TOKEN"], !token.isEmpty {
            self.apiToken = token
        } else if let token = ProcessInfo.processInfo.environment["POLAR_API_TOKEN"], !token.isEmpty {
            self.apiToken = token
        } else if let token = Self.loadTokenFromEnvFile() {
            self.apiToken = token
        } else {
            // No token available - set empty token
            self.apiToken = ""
        }
        super.init()

        // Log the token source after super.init()
        logTokenSource()
    }

    private func logTokenSource() {
        if !apiToken.isEmpty {
            if ProcessInfo.processInfo.environment["POLAR_ACCESS_TOKEN"] == apiToken {
                logger.info("🔑 Using POLAR_ACCESS_TOKEN environment variable")
            } else if ProcessInfo.processInfo.environment["POLAR_API_TOKEN"] == apiToken {
                logger.info("🔑 Using POLAR_API_TOKEN environment variable")
            } else {
                logger.info("🔑 Using token from .env file")
            }
        } else {
            logger.error("🔑 No Polar API token found! Please set POLAR_ACCESS_TOKEN or POLAR_API_TOKEN environment variable")
        }
    }
  
    // Get the appropriate base URL based on sandbox mode
    private func getBaseURL() -> String {
        return isSandbox ? sandboxBaseURL : baseURL
    }

    // Create an authenticated URLRequest for the given endpoint
    private func createAuthenticatedRequest(endpoint: String, method: String = "POST") -> URLRequest {
        let currentBaseURL = getBaseURL()
        let url = URL(string: "\(currentBaseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30.0

        // Validate token before using it
        guard !apiToken.isEmpty else {
            logger.error("🔑 Polar API token is empty - please set POLAR_ACCESS_TOKEN or POLAR_API_TOKEN environment variable")
            // Return a request that will fail with a clear error message
            _ = NSError(domain: "PolarServiceError", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "Polar API token is not configured. Please set POLAR_ACCESS_TOKEN or POLAR_API_TOKEN environment variable or create a .env file with your token."
            ])
            request.addValue("Bearer invalid", forHTTPHeaderField: "Authorization")
            return request
        }

        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Mindmic/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")", forHTTPHeaderField: "User-Agent")

        logger.info("🔑 Creating \(method) request to \(currentBaseURL)\(endpoint) in \(self.isSandbox ? "sandbox" : "production") mode")

        return request
    }
        
    struct LicenseValidationResponse: Codable {
        let status: String
        let limit_activations: Int?
        let id: String?
        let activation: ActivationResponse?
    }
    
    struct ActivationResponse: Codable {
        let id: String
    }
    
    struct ActivationRequest: Codable {
        let key: String
        let organization_id: String
        let label: String
        let meta: [String: String]
    }
    
    struct ActivationResult: Codable {
        let id: String
        let license_key: LicenseKeyInfo
    }
    
    struct LicenseKeyInfo: Codable {
        let limit_activations: Int
        let status: String
    }

    struct CheckoutLinkRequest: Codable {
        let product_id: String
        let success_url: String?
        let cancel_url: String?
        let customer_email: String?
        let metadata: [String: String]?
    }

    struct CheckoutLinkResponse: Codable {
        let id: String
        let url: String
        let customer_email: String?
        let product_id: String
        let metadata: [String: String]?
    }

    struct ErrorResponse: Codable {
        let detail: String
        let error: String?
        let error_code: String?
    }

    // Load token from .env file for local development
    private static func loadTokenFromEnvFile() -> String? {
        let projectPath = FileManager.default.currentDirectoryPath
        let envPath = "\(projectPath)/.env"

        guard FileManager.default.fileExists(atPath: envPath) else {
            return nil
        }

        do {
            let envContent = try String(contentsOfFile: envPath)
            let lines = envContent.split(separator: "\n")

            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.hasPrefix("POLAR_ACCESS_TOKEN=") {
                    let token = String(trimmedLine.dropFirst("POLAR_ACCESS_TOKEN=".count))
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    return !token.isEmpty ? token : nil
                } else if trimmedLine.hasPrefix("POLAR_API_TOKEN=") {
                    let token = String(trimmedLine.dropFirst("POLAR_API_TOKEN=".count))
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    return !token.isEmpty ? token : nil
                }
            }
        } catch {
        print("🔑 Failed to read .env file: \(error.localizedDescription)")
    }

        return nil
    }

    // Generate a unique device identifier using shared logic
    private func getDeviceIdentifier() -> String {
        return Obfuscator.getDeviceIdentifier()
    }

    // Check if currently running in sandbox mode
    func isSandboxMode() -> Bool {
        return isSandbox
    }

  // Check if token is properly configured
    func isTokenConfigured() -> Bool {
        return !apiToken.isEmpty && apiToken != "polar_oat_K7eEBU9j83yymhDvGMI8mqeNpFS3Y0JD6AM3d1Y3gWx"
    }

  // Get token status for debugging
    func getTokenStatus() -> (configured: Bool, source: String, length: Int) {
        if !apiToken.isEmpty {
            if ProcessInfo.processInfo.environment["POLAR_ACCESS_TOKEN"] == apiToken {
                return (true, "POLAR_ACCESS_TOKEN", apiToken.count)
            } else if ProcessInfo.processInfo.environment["POLAR_API_TOKEN"] == apiToken {
                return (true, "POLAR_API_TOKEN", apiToken.count)
            } else {
                return (true, ".env file", apiToken.count)
            }
        }
        return (false, "None", 0)
    }

    // Get API information for debugging
    func getAPIInfo() -> (organizationId: String, baseURL: String, isSandbox: Bool, hasToken: Bool) {
        return (organizationId, getBaseURL(), isSandbox, !apiToken.isEmpty)
    }
    
    // Check if a license key requires activation
    func checkLicenseRequiresActivation(_ key: String) async throws -> (isValid: Bool, requiresActivation: Bool, activationsLimit: Int?) {
        var request = createAuthenticatedRequest(endpoint: "/v1/license-keys/validate")
        
        let body: [String: Any] = [
            "key": key,
            "organization_id": organizationId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = httpResponse as? HTTPURLResponse {
            if !(200...299).contains(httpResponse.statusCode) {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                logger.notice("🔑 License validation failed [HTTP \(httpResponse.statusCode)]: \(errorMsg, privacy: .public)")

                // Check for specific token-related errors
                if errorMsg.contains("invalid_token") || errorMsg.contains("expired") || httpResponse.statusCode == 401 {
                    logger.error("🔑 Polar API token issue detected - token may be expired or invalid")
                    throw LicenseError.validationFailed("The Polar API token appears to be expired or invalid. Please generate a new token from your Polar dashboard and set the POLAR_ACCESS_TOKEN environment variable.")
                }

                throw LicenseError.validationFailed(errorMsg)
            }
        }
        
        // Log successful response
        let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        let statusCode = (httpResponse as? HTTPURLResponse)?.statusCode ?? 0
        logger.notice("🔑 License validation success [HTTP \(statusCode)]: \(rawResponse, privacy: .public)")
        
        let validationResponse = try JSONDecoder().decode(LicenseValidationResponse.self, from: data)
        let isValid = validationResponse.status == "granted"
        
        // If limit_activations is nil or 0, the license doesn't require activation
        let requiresActivation = (validationResponse.limit_activations ?? 0) > 0
        
        return (isValid: isValid, requiresActivation: requiresActivation, activationsLimit: validationResponse.limit_activations)
    }
    
    // Activate a license key on this device
    func activateLicenseKey(_ key: String) async throws -> (activationId: String, activationsLimit: Int) {
        var request = createAuthenticatedRequest(endpoint: "/v1/license-keys/activate")
        
        let deviceId = getDeviceIdentifier()
        let hostname = Host.current().localizedName ?? "Unknown Mac"
        
        let activationRequest = ActivationRequest(
            key: key,
            organization_id: organizationId,
            label: hostname,
            meta: ["device_id": deviceId]
        )
        
        request.httpBody = try JSONEncoder().encode(activationRequest)
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = httpResponse as? HTTPURLResponse {
            if !(200...299).contains(httpResponse.statusCode) {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                logger.notice("🔑 License activation failed [HTTP \(httpResponse.statusCode)]: \(errorMsg, privacy: .public)")

                // Check for specific token-related errors
                if errorMsg.contains("invalid_token") || errorMsg.contains("expired") || httpResponse.statusCode == 401 {
                    logger.error("🔑 Polar API token issue detected - token may be expired or invalid")
                    throw LicenseError.activationFailed("The Polar API token appears to be expired or invalid. Please generate a new token from your Polar dashboard and set the POLAR_ACCESS_TOKEN environment variable.")
                }

                // Check for specific error messages
                if errorMsg.contains("activation limit") || errorMsg.contains("maximum activations") {
                    throw LicenseError.activationLimitReached(errorMsg)
                }
                if errorMsg.contains("License key does not require activation") {
                    throw LicenseError.activationNotRequired
                }
                throw LicenseError.activationFailed(errorMsg)
            }
        }
        
        // Log successful response
        let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        let statusCode = (httpResponse as? HTTPURLResponse)?.statusCode ?? 0
        logger.notice("🔑 License activation success [HTTP \(statusCode)]: \(rawResponse, privacy: .public)")
        
        let activationResult = try JSONDecoder().decode(ActivationResult.self, from: data)
        
        return (activationId: activationResult.id, activationsLimit: activationResult.license_key.limit_activations)
    }
    
    // Validate a license key with an activation ID
    func validateLicenseKeyWithActivation(_ key: String, activationId: String) async throws -> Bool {
        var request = createAuthenticatedRequest(endpoint: "/v1/license-keys/validate")
        
        let body: [String: Any] = [
            "key": key,
            "organization_id": organizationId,
            "activation_id": activationId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = httpResponse as? HTTPURLResponse {
            if !(200...299).contains(httpResponse.statusCode) {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                logger.notice("🔑 License validation with activation failed [HTTP \(httpResponse.statusCode)]: \(errorMsg, privacy: .public)")

                // Check for specific token-related errors
                if errorMsg.contains("invalid_token") || errorMsg.contains("expired") || httpResponse.statusCode == 401 {
                    logger.error("🔑 Polar API token issue detected - token may be expired or invalid")
                    throw LicenseError.validationFailed("The Polar API token appears to be expired or invalid. Please generate a new token from your Polar dashboard and set the POLAR_ACCESS_TOKEN environment variable.")
                }

                throw LicenseError.validationFailed(errorMsg)
            }
        }
        
        // Log successful response
        let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        let statusCode = (httpResponse as? HTTPURLResponse)?.statusCode ?? 0
        logger.notice("🔑 License validation with activation success [HTTP \(statusCode)]: \(rawResponse, privacy: .public)")
        
        let validationResponse = try JSONDecoder().decode(LicenseValidationResponse.self, from: data)
        
        return validationResponse.status == "granted"
    }

    // Create a checkout link for purchasing
    func createCheckoutLink(productId: String, customerEmail: String? = nil) async throws -> CheckoutLinkResponse {
        var request = createAuthenticatedRequest(endpoint: "/v1/checkout-links", method: "POST")

        let checkoutRequest = CheckoutLinkRequest(
            product_id: productId,
            success_url: nil, // Use Polar's default success URL
            cancel_url: nil,  // Use Polar's default cancel URL
            customer_email: customerEmail,
            metadata: ["source": "mindmic_app", "device_id": getDeviceIdentifier()]
        )

        request.httpBody = try JSONEncoder().encode(checkoutRequest)

        let (data, httpResponse) = try await URLSession.shared.data(for: request)

        if let httpResponse = httpResponse as? HTTPURLResponse {
            if !(200...299).contains(httpResponse.statusCode) {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                logger.notice("🔑 Checkout link creation failed [HTTP \(httpResponse.statusCode)]: \(errorMsg, privacy: .public)")

                // Try to parse structured error response
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw LicenseError.checkoutFailed(errorResponse.detail)
                }

                // Check for specific token-related errors
                if errorMsg.contains("invalid_token") || errorMsg.contains("expired") || httpResponse.statusCode == 401 {
                    logger.error("🔑 Polar API token issue detected - token may be expired or invalid")
                    throw LicenseError.validationFailed("The Polar API token appears to be expired or invalid. Please generate a new token from your Polar dashboard.")
                }

                throw LicenseError.checkoutFailed(errorMsg)
            }
        }

        let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        let statusCode = (httpResponse as? HTTPURLResponse)?.statusCode ?? 0
        logger.notice("🔑 Checkout link created successfully [HTTP \(statusCode)]: \(rawResponse, privacy: .public)")

        let checkoutResponse = try JSONDecoder().decode(CheckoutLinkResponse.self, from: data)
        return checkoutResponse
    }

    // Validate license key with enhanced error handling
    func validateLicenseKeyWithEnhancedErrors(_ key: String, activationId: String? = nil) async throws -> (isValid: Bool, requiresActivation: Bool, activationsLimit: Int?) {
        var request = createAuthenticatedRequest(endpoint: "/v1/license-keys/validate")

        var body: [String: Any] = [
            "key": key,
            "organization_id": organizationId
        ]

        if let activationId = activationId {
            body["activation_id"] = activationId
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, httpResponse) = try await URLSession.shared.data(for: request)

            if let httpResponse = httpResponse as? HTTPURLResponse {
                if !(200...299).contains(httpResponse.statusCode) {
                    let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                    logger.notice("🔑 Enhanced license validation failed [HTTP \(httpResponse.statusCode)]: \(errorMsg, privacy: .public)")

                    // Try to parse structured error response
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw LicenseError.validationFailed(errorResponse.detail)
                    }

                    // Check for specific error patterns
                    if errorMsg.contains("invalid_token") || errorMsg.contains("expired") || httpResponse.statusCode == 401 {
                        throw LicenseError.validationFailed("API token expired or invalid. Please check your Polar configuration.")
                    }
                    if errorMsg.contains("not found") || httpResponse.statusCode == 404 {
                        throw LicenseError.validationFailed("License key not found. Please verify your license key is correct.")
                    }
                    if errorMsg.contains("revoked") || errorMsg.contains("suspended") {
                        throw LicenseError.validationFailed("License key has been revoked or suspended.")
                    }
                    if errorMsg.contains("expired") {
                        throw LicenseError.validationFailed("License key has expired.")
                    }

                    throw LicenseError.validationFailed(errorMsg)
                }
            }

            let validationResponse = try JSONDecoder().decode(LicenseValidationResponse.self, from: data)
            let isValid = validationResponse.status == "granted"
            let requiresActivation = (validationResponse.limit_activations ?? 0) > 0

            return (isValid: isValid, requiresActivation: requiresActivation, activationsLimit: validationResponse.limit_activations)

        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                throw LicenseError.networkError("Request timed out. Please check your internet connection and try again.")
            } else if urlError.code == .notConnectedToInternet {
                throw LicenseError.networkError("No internet connection. Please check your network and try again.")
            } else {
                throw LicenseError.validationFailed("Network error: \(urlError.localizedDescription)")
            }
        } catch {
            if error is LicenseError {
                throw error
            }
            throw LicenseError.validationFailed("Unexpected error: \(error.localizedDescription)")
        }
    }
}

enum LicenseError: Error, LocalizedError {
    case activationFailed(String)
    case validationFailed(String)
    case activationLimitReached(String)
    case activationNotRequired
    case checkoutFailed(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .activationFailed(let details):
            return "Failed to activate license: \(details)"
        case .validationFailed(let details):
            return "License validation failed: \(details)"
        case .activationLimitReached(let details):
            return "Activation limit reached: \(details)"
        case .activationNotRequired:
            return "This license does not require activation."
        case .checkoutFailed(let details):
            return "Failed to create checkout link: \(details)"
        case .networkError(let details):
            return "Network error: \(details)"
        }
    }
}
