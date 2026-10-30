"""Power-delivery contract reader."""

from sat_hardware_agent.contracts.power import PowerContract
from satellite1_hw.components.power_delivery import get_pd_contract


class PowerDeliveryService:
    """Read the current USB-C power-delivery contract on demand."""

    # DaemonService

    async def start(self) -> None:
        pass

    async def close(self) -> None:
        pass

    # PowerContractReader

    async def get_power_contract(self) -> PowerContract | None:
        contract = get_pd_contract()
        if contract is None or contract.voltage is None or contract.current is None:
            return None
        return PowerContract(voltage=contract.voltage, current=contract.current)
