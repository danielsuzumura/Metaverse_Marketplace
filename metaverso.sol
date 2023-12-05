// SPDX-License-Identifier: MIT

// Projeto 2: SSC0958 - Criptomoedas e Blockchain (2023)
// Tema: Metaverso e blockchain
// Daniel Suzumura - 11218921

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MetaverseMarketplace is ERC721 {
    using Counters for Counters.Counter;
    // Controla o id dos produtos
    Counters.Counter private _productCounter;

    // Controla a quantidade de produtos vendidos
    Counters.Counter private _productSoldCounter;

    // taxa de transacao cobrada
    uint256 public transactionFee = 1 ether;

    // define owner do contrato
    address payable public owner;

    // define variavel do tipo Produto
    struct Product {
        // id do produto
        uint256 id;
        // quem eh o dono atual do produto
        address owner;
        // quem esta vendendo o produto
        address seller;
        // nome do produto
        string name;
        // preco do produto
        uint256 price;
    }

    // estrutura de dados para armazenar os produtos vendidos
    mapping(uint256 => Product) private _products;

    // evento para notificar que um item foi listado
    event ProductListed(uint256 indexed productId, address indexed owner, address indexed seller, string name, uint256 price);
    // evento para notificar que um item foi vendido
    event ProductSold(uint256 indexed productId, address indexed buyer, uint256 amount);

    // modificador para verificar se quem enviou a mensagem eh o owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        // define o owner na execucao do contrato
        owner = payable(msg.sender);
    }

    // Funcao para criar um NFT do produto e adiciona-lo para venda
    function sellProduct(string memory name, uint256 price) public payable {
        // verificar se o usuario possui saldo suficiente para pagar 
        require(msg.value >= transactionFee, "Saldo insuficiente para realizar transacao");

        // criar um NFT
        _productCounter.increment();
        uint256 productId = _productCounter.current();
        _mint(msg.sender, productId);
        _products[productId] = Product(productId, address(0x0), msg.sender, name, price);

        // Cobrar o valor da taxa de transacao para listar um item
        owner.transfer(transactionFee);

        // emitir evento que um produto foi criado
        emit ProductListed(productId, address(0x0), msg.sender, name, price);
    }

    // Funcao para comprar um produto
    function buyProduct(uint256 productId) public payable {
        // produto que o usuario deseja comprar
        Product storage product = _products[productId];

        // verifica se ha saldo suficiente para comprar o produto e pagar a taxa de transacao
        require(msg.value >= product.price+transactionFee, "Saldo insuficiente");
        
        // realizar a transferencia do Ether
        _transfer(product.seller, msg.sender, productId);
        // Cobrar o valor da taxa de transacao para listar um item
        owner.transfer(transactionFee);

        // define o comprador como owner do produto
        product.owner = payable(msg.sender);

        // emitir evento que um produto foi vendido
        emit ProductSold(productId, msg.sender, msg.value);
    }
    // Retorna a taxa de transferencia
    function getTaxaTransacao() public view returns (uint256){
        return transactionFee;
    }

    // Define a taxa de transferencia
    // Apenas o Owner pode executar
    function setTaxaTransacao(uint256 taxa) public onlyOwner {
        transactionFee = taxa;
    }

    // Obter lista com os produtos disponiveis no marketplace
     function getProductsOnSale() public view returns (Product[] memory) {
        uint productCount = _productCounter.current();
        // quantidade de produtos a venda
        uint productAvailable = _productCounter.current() - _productSoldCounter.current();

        Product[] memory products = new Product[](productAvailable);
        uint productsIndex = 0;


        for (uint i = 0; i < productCount; i++) {
            if (_products[i + 1].owner == address(0x0)) { // verifica se o produto nao possui owner
                uint currentId =  i + 1;
                Product storage product_i = _products[currentId];
                products[productsIndex] = product_i;
                productsIndex += 1;
            }
        }
        return products;
    }

    // Obter lista com os produtos que o usuario possui
    function getMyProducts() public view returns (Product[] memory) {
        uint productCount = _productCounter.current();
        uint myProductCount = 0;

        for (uint i = 0; i < productCount; i++) {
            if (_products[i + 1].owner == msg.sender) { // verifica se o usuario eh o dono do produto
                myProductCount += 1;
            }
        }

        Product[] memory product_array = new Product[](myProductCount);
        uint productsIndex = 0;

        for (uint i = 0; i < productCount; i++) {
            if (_products[i + 1].owner == msg.sender) { // verifica se o usuario eh o dono do produto
                uint currentId =  i + 1;
                Product storage product_i = _products[currentId];
                product_array[productsIndex] = product_i;
                productsIndex += 1;
            }
        }
        return product_array;
    }

    // Obter lista com os produtos que o usuario esta vendendo
    function getMySellingProducts() public view returns (Product[] memory) {
        uint productCount = _productCounter.current();
        uint myProductCount = 0;

        for (uint i = 0; i < productCount; i++) {
            if (_products[i + 1].seller == msg.sender) { // verifica se o usuario eh o vendedor do produto
                myProductCount += 1;
            }
        }

        Product[] memory product_array = new Product[](myProductCount);
        uint productsIndex = 0;

        for (uint i = 0; i < productCount; i++) {
            if (_products[i + 1].seller == msg.sender) { // verifica se o usuario eh o vendedor do produto
                uint currentId =  i + 1;
                Product storage product_i = _products[currentId];
                product_array[productsIndex] = product_i;
                productsIndex += 1;
            }
        }
        return product_array;
    }
}
