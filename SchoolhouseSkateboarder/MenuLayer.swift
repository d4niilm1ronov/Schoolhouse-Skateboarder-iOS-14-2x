import UIKit
import SpriteKit

/// Класс для отображение меню
class MenuLayer: SKSpriteNode {
    
    func display(message: String, score: Int?) {
        
        // Добавление надписи на экран
        let messageLabel: SKLabelNode = SKLabelNode(text: message)
        
        let messageX = -frame.width
        let messageY = frame.height / 2.0
        
        messageLabel.position = CGPoint(x: messageX, y: messageY)
        
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.fontName = "Courier-Bold"
        messageLabel.fontSize = 24
        messageLabel.zPosition = 20
        
        addChild(messageLabel)
        
        // Добавление анимации для надписи
        messageLabel.run( SKAction.moveTo(x: frame.width / 2, duration: 0.3) )
        
        // Если количество очков переданно – то их надо показать
        if let scoreToDisplay = score {
            
            // Добавление надписи на экран
            let messageScoreLabel: SKLabelNode = SKLabelNode(text: String(format: "Очки: %05d", scoreToDisplay))
            
            messageScoreLabel.position = CGPoint(x: -frame.width, y: frame.height / 2.0 - 50)
            messageScoreLabel.horizontalAlignmentMode = .center
            messageScoreLabel.fontName = "Courier-Bold"
            messageScoreLabel.fontSize = 20
            messageScoreLabel.zPosition = 20
            
            addChild(messageScoreLabel)
            
            // Добавление анимации для надписи
            messageScoreLabel.run( SKAction.moveTo(x: frame.width / 2, duration: 0.3) )
        }
        
    }
}
