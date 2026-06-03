#include <iostream>
#include <string>
#include <vector>
#include <cstdint>

std::string readMessage() {
    uint32_t length = 0;
    std::cin.read(reinterpret_cast<char*>(&length), 4);
    if (!std::cin || length == 0) {
        return "";
    }

    std::vector<char> buffer(length);
    std::cin.read(buffer.data(), length);
    return std::string(buffer.begin(), buffer.end());
}

void sendMessage(const std::string& jsonMessage) {
    uint32_t length = static_cast<uint32_t>(jsonMessage.length());
    std::cout.write(reinterpret_cast<const char*>(&length), 4);
    std::cout.write(jsonMessage.data(), length);
    std::cout.flush();
}

int main() {
#ifdef _WIN32
    _setmode(_fileno(stdin), _O_BINARY);
    _setmode(_fileno(stdout), _O_BINARY);
#endif
    while (true) {
        std::string input = readMessage();
        if (input.empty()) {
            break; 
        }

        std::string jsonResponse = "{"
            "\"message\": \"Hello from native host (C++)\","
            "\"input\": " + input +
        "}";

        sendMessage(jsonResponse);
    }
    return 0;
}
