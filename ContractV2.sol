// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract SubastaSimple {
    address payable public beneficiario;
    uint public finSubasta;

    address payable public propietario;

    address public mayorPujador;
    uint public mayorPuja;

    mapping(address => uint) devolucionesPendientes;
    Pujas[] public todasLasPujas;

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
            finSubasta = block.timestamp + (_tiempoSubasta * 60); // El tiempo de subasta se introduce en minutos
        } else {
            finSubasta = 0; // Subasta indefinida si no se especifica tiempo
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

    // Nueva función que devuelve el tiempo restante de la subasta
    function tiempoRestante() public view returns (uint) {
        if (finSubasta == 0 || block.timestamp >= finSubasta) {
            return 0; // Subasta indefinida o ya finalizada
        } else {
            return finSubasta - block.timestamp; // Tiempo restante en segundos
        }
    }

    function verificarFinAutomatico() internal {
        if (finSubasta != 0 && block.timestamp >= finSubasta && !finalizada) {
            finalizada = true;
            emit SubastaTerminadaAutomaticamente();  // Emitimos el evento cuando la subasta termina automáticamente
            emit SubastaFinalizada(mayorPujador, mayorPuja);

            // Transferir los fondos al beneficiario
            if (mayorPuja > 0) {
                beneficiario.transfer(mayorPuja);
            }
        }
    }

    function pujar() external payable {
        verificarFinAutomatico();  // Revisamos si la subasta ha terminado antes de aceptar nuevas pujas
        require(!finalizada, "La subasta ya ha finalizado");
        require(finSubasta == 0 || block.timestamp < finSubasta, "La subasta ya ha finalizado");
        require(msg.value > mayorPuja, "Ya existe una puja mayor");

        if (mayorPuja != 0) {
            devolucionesPendientes[mayorPujador] += mayorPuja;
        }

        mayorPujador = msg.sender;
        mayorPuja = msg.value;

        // Registrar la puja
        todasLasPujas.push(Pujas(msg.sender, msg.value));

        emit PujaAumentada(msg.sender, msg.value);

        // Extender el tiempo si la puja es cercana al final de la subasta
        if (finSubasta != 0 && finSubasta - block.timestamp < tiempoExtension) {
            finSubasta += tiempoExtension;
        }
    }

    // Solo el beneficiario puede finalizar la subasta
    function finalizarSubasta() external soloBeneficiario {
        verificarFinAutomatico();  // Si alguien intenta finalizar manualmente, revisamos el estado actual
        require(!finalizada, "La subasta ya ha sido finalizada");

        finalizada = true;
        emit SubastaFinalizada(mayorPujador, mayorPuja);

        beneficiario.transfer(mayorPuja);
    }

    function cancelarSubasta() external soloBeneficiario {
        require(!finalizada, "La subasta ya ha finalizado");

        finalizada = true;

        // Devolver todas las pujas a los postores
        for (uint i = 0; i < todasLasPujas.length; i++) {
            address pujador = todasLasPujas[i].pujador;
            uint cantidad = todasLasPujas[i].cantidad;

            // Solo devolver si la cantidad no es cero
            if (cantidad > 0) {
                devolucionesPendientes[pujador] += cantidad;
            }
        }

        emit SubastaFinalizada(address(0), 0);
    }

    function obtenerBalance() public view returns (uint) {
        return address(this).balance;
    }

    function obtenerTodasLasPujas() external view returns (Pujas[] memory) {
        return todasLasPujas;
    }

    function retirar() external {
        uint cantidad = devolucionesPendientes[msg.sender];
        require(cantidad > 0, "No hay devoluciones pendientes");

        devolucionesPendientes[msg.sender] = 0;
        payable(msg.sender).transfer(cantidad);
    }
}
