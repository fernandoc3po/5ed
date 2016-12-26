//
//  CarroService.swift
//  Carros
//
//  Created by Ricardo Lecheta on 7/12/14.
//  Copyright (c) 2014 Ricardo Lecheta. All rights reserved.
//

import Foundation

class CarroService {
    
    class func getCarrosByTipo(_ tipo: String, cache:Bool, callback: @escaping (_ carros:Array<Carro>?, _ error:Error?) -> Void) {
        
        var db = CarroDB()
        
        // Busca os carros do banco de dados
        let carros : Array<Carro> = cache ? db.getCarrosByTipo(tipo) : []
        
        // Se existir no banco de dados retorna
        if(carros.count > 0) {
            db.close()
            
            for c in carros {
                print(c.nome)
                print(c.url_foto)
            }
            
            // Retorna os carros pela função de retorno
            callback(carros, nil)
            print("Retornando carros \(tipo) do banco")
            return
        }
        
        // Cria a URL e Request
        let http = URLSession.shared
        let url = URL(string:"http://www.livroiphone.com.br/carros/carros_"+tipo+".json")!
        let request = URLRequest(url: url)
        
        // Faz a requisicao HTTP
        let task = http.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
            if(error != nil) {
                // Chama o callback de erro
                callback(nil, error!)
            } else {
                // Faz parser de JSON. Cria lista de carros.
                let carros = CarroService.parserJson(data!)
                
                if(carros.count > 0) {
                    db = CarroDB()
                    
                    db.deleteCarrosTipo(tipo)
                    
                    for c in carros {
                        // Salva o tipo do carro
                        c.tipo = tipo
                        // Salva o carro no banco
                        db.save(c)
                    }
                    db.close()
                }
                
                DispatchQueue.main.sync(execute: {
                    callback(carros, nil)
                })
                
            }
        })
        task.resume()
    }
    
    
    // Busca por os carros pelo tipo: esportivos, clássicos ou luxo
    class func getCarrosByTipoFromFile(_ tipo: String) -> Array<Carro> {
        let file = "carros_" + tipo
        
        let path = Bundle.main.path(forResource: file, ofType: "json")
        
        if(path == nil) {
            // Não encontrou o arquivo no projeto
            return [] // array vazio
        }
        
        // Conteúdo binário do arquivo
        let data = try? Data(contentsOf: URL(fileURLWithPath: path!))
        
        if(data == nil) {
            // Não conseguiu ler o arquivo
            return [] // array vazio
        }
        
        if (data!.count == 0) {
            print("NSData vazio");
            return [] // array vazio
        }
        
        let carros = self.parserJson(data!)
        
        //let carros = parserXML_DOM(data!)
        
        for c in carros {
            // Atualiza o tipo do carro vamos precisar depois
            c.tipo = tipo
        }
        
        return carros
    }
    
    // Parser JSON
    class func parserJson(_ data: Data) -> Array<Carro> {
        
        var carros : Array<Carro> = []
        
        // Faz a leitura do JSON, converte para dictionary
        do {
            let dict = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            // Dictionary para todos os carros
            let jsonCarros: NSDictionary = dict["carros"] as! NSDictionary
            let arrayCarros: NSArray = jsonCarros["carro"] as! NSArray
            
            // Array de carros
            for obj in arrayCarros {
                let dict = obj as! NSDictionary
                let carro = Carro()
                carro.nome = dict["nome"] as! String
                carro.desc = dict["desc"] as! String
                carro.url_info = dict["url_info"] as! String
                carro.url_foto = dict["url_foto"] as! String
                carro.url_video = dict["url_video"] as! String
                carro.latitude = dict["latitude"] as! String
                carro.longitude = dict["longitude"] as! String
                carros.append(carro)
            }
        } catch let error as NSError {
            print("Erro ao ler JSON \(error)")
        }
        // Retorna a lista de carros
        return carros
    }
    
    // Parser de XML com DOM
    class func parserXML_DOM(_ data: Data) -> Array<Carro> {
        var carros : Array<Carro> = []
        
        // Lê a tag raiz <carros>
        let document = try? SMXMLDocument(data: data)
        
        if(document == nil) {
            print("Erro ao ler os dados");
            return carros
        }
        
        let root = document!.root as SMXMLElement
        let tagCarros = root.childrenNamed("carro") as NSArray
        
        // Percorre todas as tags <carro>
        for x in  tagCarros {
            let xml = x as! SMXMLElement
            
            let carro = Carro()
            carro.nome = xml.value(withPath: "nome")
            carro.desc = xml.value(withPath: "desc")
            carro.url_info = xml.value(withPath: "url_info")
            carro.url_foto = xml.value(withPath: "url_foto")
            carro.url_video = xml.value(withPath: "url_video")
            if(xml.value(withPath: "latitude") != nil) {
                carro.latitude = xml.value(withPath: "latitude")
            }
            if(xml.value(withPath: "longitude") != nil) {
                carro.longitude = xml.value(withPath: "longitude")
            }
            
            carros.append(carro)
            
        }
        
        return carros
    }
    
    // Parser de XML com SAX
    class func parserXML_SAX(_ data: Data) -> Array<Carro> {
        var carros : Array<Carro> = []
        
        let xmlParser = XMLParser(data:data)
        
        let carrosParser = XMLCarroParser()
        xmlParser.delegate = carrosParser
        
        // Inicia o parser com o NSXMLParser, o que vai chamar a classe XMLCarroParser
        let ok = xmlParser.parse()
        
        if (ok) {
            // Fez o parser com sucesso, retorna a lista de carros
            carros = carrosParser.carros
            
            let count = carros.count
            
            print("Parser, encontrado \(count) carros");
            
        } else {
            print("Erro no parser");
        }
        
        // Retorna a lista de carros
        return carros
    }
    
    // Retorna um array de carros de forma simples
    class func getCarros() -> Array<Carro> {
        
        var carros : Array<Carro> = []
        
        for i in 1...20 {
            let c = Carro()
            c.nome = "Ferrari " + String(i)
            c.desc = "Desc Carro " + String(i)
            c.url_foto = "Ferrari_FF.png"
            c.url_info = "http://www.google.com.br"
            
            // Adiciona o carro no array
            carros.append(c)
        }
        
        return carros
    }
}
