import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { HardhatEthersHelpers } from "@nomiclabs/hardhat-ethers/types"
import { ContractAddressOrInstance } from "@openzeppelin/hardhat-upgrades/dist/utils"
import { Contract, ethers } from "ethers"
import { hexStripZeros } from "ethers/lib/utils"
import { HardhatRuntimeEnvironment } from "hardhat/types/runtime"
import { SupportedChain } from "../config/NetworkConfig"
import { colorLog, Colors } from "../utils/ColorConsole"
import { DeploymentHelper } from "../utils/DeploymentHelper"

export type XCallDomains = {
	[key in SupportedChain | any]?: XCallConfig
}

interface XCallConfig {
	chainDomain: number
	token: string
}

const xCallDomains: XCallDomains = {
	rinkeby: {
		chainDomain: 1111,
		token: "0x3FFc03F05D1869f493c7dbf913E636C6280e0ff9",
	},
	goerli: {
		chainDomain: 3331,
		token: "0x3FFc03F05D1869f493c7dbf913E636C6280e0ff9",
	},
	kovan: {
		chainDomain: 2221,
		token: "0x3FFc03F05D1869f493c7dbf913E636C6280e0ff9",
	},
}

export default async function execute(
	params: any,
	hre: HardhatRuntimeEnvironment
): Promise<void> {
	const scenarioLogic: Scenario = new Scenario(hre, params)
	await scenarioLogic.initScenario()

	switch (params.type.toLowerCase()) {
		case "trust":
			await scenarioLogic.trustXapp()
			break
		case "retry":
			await scenarioLogic.retryScenario()
			break
		default:
			break
	}
}

class Scenario {
	XAPP_NAME: string = "XApp"
	TARGET_NAME: string = "Target"

	signer?: SignerWithAddress
	params: any
	hre: HardhatRuntimeEnvironment
	helper: DeploymentHelper
	xApp?: Contract
	target?: Contract
	destinationAddresses?: any

	constructor(hre: HardhatRuntimeEnvironment, params: any) {
		this.helper = new DeploymentHelper(
			{ TX_CONFIRMATIONS: 1, ContractConfigs: {} },
			hre
		)
		this.hre = hre
		this.params = params
	}

	async initScenario() {
		const [signer] = await this.hre.ethers.getSigners()
		this.signer = signer

		const [foundxApp, originXAppAddress] =
			await this.helper.tryToGetSaveContractAddress(this.XAPP_NAME)

		const [foundTarget, originTarget] =
			await this.helper.tryToGetSaveContractAddress(this.TARGET_NAME)

		if (!foundxApp || !foundTarget)
			throw "XApp or Target not found on origin"

		this.destinationAddresses = require("../deployments/" +
			this.params.destination +
			"_deployment.json")

		const xAppFactory = await this.hre.ethers.getContractFactory("XApp")
		const targetFactory = await this.hre.ethers.getContractFactory(
			"Target"
		)
		this.xApp = xAppFactory.attach(originXAppAddress)
		this.target = targetFactory.attach(originTarget)
	}

	async trustXapp() {
		await this.helper.sendAndWaitForTransaction(
			this.xApp!.registerNewXApp(
				xCallDomains[this.params.destination]?.chainDomain,
				this.destinationAddresses[this.XAPP_NAME].address
			)
		)

		colorLog(
			Colors.green,
			`${this.params.origin}-${this.xApp!.address} registered XApp from ${
				this.params.destination
			}-${this.destinationAddresses[this.XAPP_NAME].address}`
		)
	}

	async retryScenario() {
		switch (this.params.action.toLowerCase()) {
			case "first":
				await this.retryFristTime()
				break
			case "giveAccess":
				await this.retryGiveAccess()
				break
			case "retry":
				await this.retryRetry()
				break
		}
	}

	private async retryFristTime() {
		//payload: updateUselessValue(address,uint256), signer.address, 1234

		console.log(
			`Target Destination: ${
				this.destinationAddresses[this.TARGET_NAME].address
			}`
		)

		console.log(
			`Destination Domain: ${
				xCallDomains[this.params.destination]?.chainDomain
			}`
		)

		let unsignedTx = await this.xApp!.populateTransaction.sendXCall(
			this.destinationAddresses[this.TARGET_NAME].address,
			xCallDomains[this.params.origin]!.token,
			0,
			xCallDomains[this.params.destination]!.chainDomain,
			true,
			"0x3f22558700000000000000000000000087209dc4b76b14b67bc5e5e5c0737e7d002a219c00000000000000000000000000000000000000000000000000000000000004d2"
		)

		unsignedTx.gasLimit = ethers.BigNumber.from("300000")
		let txResponse = await this.signer!.sendTransaction(unsignedTx)

		colorLog(
			Colors.green,
			`Tx Response ${(await txResponse.wait()).transactionHash}`
		)
	}

	private async retryGiveAccess() {
		await this.helper.sendAndWaitForTransaction(
			this.target!.allowUserToXCall(this.signer!.address, true)
		)

		colorLog(Colors.green, "Permission has been granted")
	}

	private async retryRetry() {
		await this.target!.changeUselessValue(92813)

		await this.helper.sendAndWaitForTransaction(
			this.xApp!.retryFailedCall(
				xCallDomains[this.params.origin],
				await this.xApp!.getLastFailedNonce()
			)
		)

		colorLog(
			Colors.green,
			`Last Value: ${92813} after Call value ${await this.target!.uselessValue()}`
		)
	}
}
