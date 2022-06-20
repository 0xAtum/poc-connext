import { IDeployConfig } from "../../config/DeployConfig"
import { DeploymentHelper } from "../../utils/DeploymentHelper"
import { HardhatRuntimeEnvironment } from "hardhat/types/runtime"
import { HardhatEthersHelpers } from "@nomiclabs/hardhat-ethers/types"
import { colorLog, Colors } from "../../utils/ColorConsole"

export class Deployer {
	config: IDeployConfig
	helper: DeploymentHelper
	ethers: HardhatEthersHelpers
	hre: HardhatRuntimeEnvironment

	constructor(config: IDeployConfig, hre: HardhatRuntimeEnvironment) {
		this.hre = hre
		this.ethers = hre.ethers
		this.config = config
		this.helper = new DeploymentHelper(config, hre)
	}

	async run() {
		const networkName: string = this.hre.network.name
		const configs = this.config.ContractConfigs[networkName]

		if (configs == undefined) throw `${networkName} isn't configured`

		await this.helper.deployContractByName(
			"XApp",
			"XApp",
			configs!.connext,
			configs!.domain
		)

		await this.helper.deployContractByName("Target")
	}
}
