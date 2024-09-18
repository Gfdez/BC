// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FabricaContract {
    uint idDigits = 16;

    struct Producto {
        string nombre;
        uint identificacion;
    }

    Producto[] public productos;

    function crearProducto(string memory _nombre, uint _id) private {
        productos.push(Producto(_nombre, _id));
        emit NuevoProducto(productos.length - 1, _nombre, _id);
    }

    function _generarIdAleatorio(string memory _str) private view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        uint idModulus = 10 ** idDigits;
        return rand % idModulus;
    }

    function crearProductoAleatorio(string memory _nombre) public {
        uint randId = _generarIdAleatorio(_nombre);
        crearProducto(_nombre, randId);
    }

    event NuevoProducto(uint _arrayProductoId, string _nombre, uint _id);
    mapping(uint => address) public productoAPropietario;
    mapping(address => uint) public propietarioProductos;

    function Propiedad(uint _productoId) public {
        require(_productoId >= 0 && _productoId < productos.length);
        productoAPropietario[_productoId] = msg.sender;
        propietarioProductos[msg.sender]++;
    }
    function getProductosPorPropietario(address _propietario) external view returns (uint[] memory) {
        uint[] memory resultados = new uint[](propietarioProductos[_propietario]);
        uint contador = 0;
        for (uint i = 0; i < productos.length; i++) {
            if (productoAPropietario[i] == _propietario) {
                resultados[contador] = i;
                contador++;
            }
        }
        return resultados;
    }
}