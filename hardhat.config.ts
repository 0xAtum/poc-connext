import fs from "fs"
import { secrets } from "./.secrets"

import { HardhatUserConfig, subtask, task } from "hardhat/config"
import { TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS } from "hardhat/builtin-tasks/task-names"
import "hardhat-preprocessor"
import "@typechain/hardhat"

import "@nomiclabs/hardhat-etherscan"
import "@nomiclabs/hardhat-waffle"
import "@openzeppelin/hardhat-upgrades"

import deploy from "./scripts/tasks/DeployTask"
import scenarioExec from "./scripts/tasks/TestnetTest"

task("deploy", "Deploy task")
	.addParam("env", "localhost | testnet | mainnet", "testnet")
	.setAction(deploy)

task("execute", "Execute Code logic")
	.addParam("type", "trust | retry")
	.addParam("origin", "Origin chain name")
	.addParam("destination", "Destination chain name")
	.addOptionalParam(
		"action",
		"Retry Action type, First | giveAccess | retry"
	)
	.setAction(scenarioExec)

subtask(TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS).setAction(
	async (_, __, runSuper) => {
		const paths = await runSuper()
		return paths.filter(
			(p: string) => !p.endsWith(".t.sol") || p.includes("/mock/")
		)
	}
)

function getRemappings() {
	return fs
		.readFileSync("remappings.txt", "utf8")
		.split("\n")
		.filter(Boolean)
		.map(line => line.trim().split("="))
}

const config: HardhatUserConfig = {
	defaultNetwork: "localhost",
	networks: {
		localhost: {
			url: "http://localhost:8545",
		},
		rinkeby: {
			url: secrets.networks.rinkeby!.RPC_URL || "",
			accounts: [secrets.networks.rinkeby!.PRIVATE_KEY],
		},
		kovan: {
			url: secrets.networks.kovan!.RPC_URL || "",
			accounts: [secrets.networks.kovan!.PRIVATE_KEY],
		},
		goerli: {
			url: secrets.networks.goerli!.RPC_URL || "",
			accounts: [secrets.networks.goerli!.PRIVATE_KEY],
		},
		mainnet: {
			url: secrets.networks.mainnet!.RPC_URL,
			accounts: [secrets.networks.mainnet!.PRIVATE_KEY],
		},
	},
	etherscan: {
		apiKey: {
			mainnet: secrets.networks.mainnet?.ETHERSCAN_API_KEY!,
			rinkeby: secrets.networks.rinkeby?.ETHERSCAN_API_KEY!,
			kovan: secrets.networks.kovan?.ETHERSCAN_API_KEY!,
			goerli: secrets.networks.goerli?.ETHERSCAN_API_KEY!,
		},
	},
	solidity: {
		version: "0.8.14",
		settings: {
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
	paths: {
		sources: "./src",
		cache: "./hardhat/cache",
		artifacts: "./hardhat/artifacts",
	},
	preprocess: {
		eachLine: hre => ({
			transform: (line: string) => {
				if (line.match(/^\s*import /i)) {
					getRemappings().forEach(([find, replace]) => {
						if (line.match(find)) {
							line = line.replace(find, replace)
						}
					})
				}
				return line
			},
		}),
	},
}

export default config
