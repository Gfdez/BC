// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Subasta {
    address payable public beneficiario;
    uint public finSubasta;

    address payable public propietario;

    address public mayorPujador;
    uint public mayorPuja;

    bool finalizada;
    uint public tiempoExtension = 10 minutes;

    struct Pujas {
        address pujador;
        uint cantidad;
    }

    event PujaAumentada(address pujador, uint cantidad);
    event SubastaFinalizada(address ganador, uint cantidad);
    event SubastaTerminadaAutomaticamente(); // Nuevo evento

    constructor(uint _tiempoSubasta) {
        beneficiario = payable(msg.sender);
        if (_tiempoSubasta > 0) {
            finSubasta = block.timestamp + (_tiempoSubasta * 60); // Tiempo en minutos
        } else {
            finSubasta = 0; // Subasta indefinida
        }
    }

    modifier soloBeneficiario() {
        require(msg.sender == beneficiario, "Solo el beneficiario puede ejecutar esta funcion");
        _;
    }

    function obtenerBeneficiario() external view returns (address) {
        return beneficiario;
    }

    function obtenerMayorPuja() public view returns (address, uint) {
        return (mayorPujador, mayorPuja);
    }

    function tiempoRestante() public view returns (uint) {
        if (finSubasta == 0 || block.timestamp >= finSubasta) {
            return 0;
        } else {
            return finSubasta - block.timestamp; // Tiempo en segundos
        }
    }

    function verificarFinAutomatico() internal {
        if (finSubasta != 0 && block.timestamp >= finSubasta && !finalizada) {
            finalizada = true;
            emit SubastaTerminadaAutomaticamente();
            emit SubastaFinalizada(mayorPujador, mayorPuja);

            // Transferir los fondos al beneficiario
            if (mayorPuja > 0) {
                beneficiario.transfer(mayorPuja);
            }
        }
    }

    function pujar() public payable {
        require(block.timestamp < finSubasta, "La subasta ha terminado");
        require(msg.value > mayorPuja, "La puja debe ser mayor que la actual");

        if (mayorPujador != address(0)) {
            payable(mayorPujador).transfer(mayorPuja);
        }

        mayorPujador = msg.sender;
        mayorPuja = msg.value;

        emit PujaAumentada(msg.sender, msg.value);
    }

    function finalizarSubasta() external soloBeneficiario {
        verificarFinAutomatico();
        require(!finalizada, "La subasta ya ha sido finalizada");

        finalizada = true;
        emit SubastaFinalizada(mayorPujador, mayorPuja);

        beneficiario.transfer(mayorPuja);
    }

    function cancelarSubasta() external soloBeneficiario {
        require(!finalizada, "La subasta ya ha finalizado");

        finalizada = true;

        if (mayorPuja > 0) {
            payable(mayorPujador).transfer(mayorPuja);
        }

        emit SubastaFinalizada(mayorPujador, mayorPuja);
    }

}
