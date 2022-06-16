import { IDeployConfig } from "../../config/DeployConfig"
import { Deployer } from "./Deployer"
import { HardhatRuntimeEnvironment } from "hardhat/types/runtime"

const config: IDeployConfig = {
	TX_CONFIRMATIONS: 1,
	ContractConfigs: {
		rinkeby: {
			connext: "0xB3e787Fcbc3473016da9ab568f984A1D61339710",
			domain: 1111,
		},
		kovan: {
			connext: "0x6B5C0b9B0a1525b7aC8fFAc12aDf708361137F02",
			domain: 2221,
		},
		goerli: {
			connext: "0xEC3A723DE47a644b901DC269829bf8718F175EBF",
			domain: 3331,
		},
	},
}

export async function execute(hre: HardhatRuntimeEnvironment) {
	await new Deployer(config, hre).run()
}
