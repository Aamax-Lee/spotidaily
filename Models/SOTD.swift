//
//
//  Created by Aamax Lee on 30/4/2024.
//

import UIKit
import FirebaseFirestoreSwift

enum CodingKeys: String, CodingKey {
    case id
    case name
    case artist
    case image
    case quote
}
 
 
//sotd object to store submission information for the song of the day page
class SOTD: NSObject, Codable {
    @DocumentID var id: String?
    var name: String?
    var artist: String?
    var image: String?
    var quote: String? 
}
 
