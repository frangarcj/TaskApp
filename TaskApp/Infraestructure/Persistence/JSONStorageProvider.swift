import Foundation

class JSONStorageProvider: StorageProvider {
    private let fileURL: URL
    
    init(filename: String = "tasks.json") {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        print("Documents Directory: \(documentsDirectory.path)")
        self.fileURL = documentsDirectory.appendingPathComponent(filename)
    }
    
    func loadTasks() async throws -> [Task] {
        let data = try Data(contentsOf: fileURL)
        let tasks = try JSONDecoder().decode([Task].self, from: data)
        return tasks
    }
    
    func saveTasks(tasks: [Task]) async throws {
        do {
            let data = try JSONEncoder().encode(tasks)
            // La carpeta Documentos no existe en todos los sistemas (Linux mínimo, WSL).
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: fileURL)
        } catch {
            print("Error saving tasks: \(error)")
        }
    }
}
