import SwiftUI

struct RichText: View {
    let text: String
    
    var body: some View {
        if text.contains("^{") || text.contains("_{") {
            SubSuperScriptText(
                inputString: text,
                bodyFont: .body,
                subScriptFont: .caption2,
                baseLine: 4
            )
        } else if let attributed = try? AttributedString(markdown: text) {
            Text(attributed)
        } else {
            Text(text)
        }
    }
}

struct SubSuperScriptText: View {
    let inputString: String
    let bodyFont: Font
    let subScriptFont: Font
    let baseLine: CGFloat
    
    var body: some View {
        var string = inputString
        var composed = Text("")
        var hasContent = false
        
        func append(_ t: Text) {
            if hasContent {
                composed = Text("\(composed)\(t)")
            } else {
                composed = t
                hasContent = true
            }
        }
        
        while let validIndex = string.firstIndex(where: { ch in ch == "_" || ch == "^" }) {
            let prefix = string[..<validIndex]
            var remainder = string[validIndex...]
            
            if !prefix.isEmpty {
                append(Text(String(prefix)).font(bodyFont))
            }
            
            if remainder.count < 3 {
                append(Text(String(remainder)).font(bodyFont))
                return composed
            }
            
            var scriptType = remainder.first!
            remainder = remainder.dropFirst()
            
            var scriptString = ""
            if remainder.first != "{" {
                scriptString.append(scriptType)
                scriptType = " "
            } else if let closingIndex = remainder.firstIndex(where: { $0 == "}" }) {
                remainder = remainder.dropFirst()
                scriptString = String(remainder[..<closingIndex])
                remainder = remainder[closingIndex...].dropFirst()
            } else {
                return Text(inputString).font(bodyFont)
            }
            
            switch scriptType {
            case "^":
                append(
                    Text(scriptString)
                        .font(subScriptFont)
                        .baselineOffset(baseLine)
                )
            case "_":
                append(
                    Text(scriptString)
                        .font(subScriptFont)
                        .baselineOffset(-baseLine)
                )
            default:
                append(Text(scriptString).font(bodyFont))
            }
            
            string = String(remainder)
        }
        
        if !string.isEmpty {
            append(Text(string).font(bodyFont))
        }
        
        return composed
    }
}

struct EquationDisplay: View {
    let equation: String
    var label: String?
    var size: CGFloat = 20
    
    var body: some View {
        VStack(spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(equation)
                .font(.system(size: size, weight: .medium, design: .serif))
                .foregroundStyle(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct ScriptText: View {
    let raw: String
    var baseSize: CGFloat = 16
    var weight: Font.Weight = .regular
    var design: Font.Design = .serif
    var superOffset: CGFloat = 6
    var subOffset: CGFloat = 3
    
    var body: some View {
        buildText(from: raw)
    }
    
    private func buildText(from input: String) -> Text {
        let characters = Array(input)
        let baseFont = Font.system(size: baseSize, weight: weight, design: design)
        let scriptFont = Font.system(size: baseSize * 0.7, weight: weight, design: design)
        
        var result = Text("")
        var hasContent = false
        var currentPlainStart = 0
        var index = 0
        
        func append(_ text: Text) {
            if hasContent {
                result = Text("\(result)\(text)")
            } else {
                result = text
                hasContent = true
            }
        }
        
        while index < characters.count {
            let ch = characters[index]
            
            if (ch == "^" || ch == "_"),
               index + 2 < characters.count,
               characters[index + 1] == "{" {
                
                let isSuper = (ch == "^")
                var end = index + 2
                while end < characters.count && characters[end] != "}" {
                    end += 1
                }
                
                if end < characters.count {
                    if currentPlainStart < index {
                        let plain = String(characters[currentPlainStart..<index])
                        if !plain.isEmpty {
                            append(Text(plain).font(baseFont))
                        }
                    }
                    
                    let scriptContent = String(characters[index + 2..<end])
                    if !scriptContent.isEmpty {
                        let offset = isSuper ? superOffset : -subOffset
                        append(
                            Text(scriptContent)
                                .font(scriptFont)
                                .baselineOffset(offset)
                        )
                    }
                    
                    index = end + 1
                    currentPlainStart = index
                    continue
                }
            }
            
            index += 1
        }
        
        if currentPlainStart < characters.count {
            let plain = String(characters[currentPlainStart..<characters.count])
            if !plain.isEmpty {
                append(Text(plain).font(baseFont))
            }
        }
        
        return result
    }
}
