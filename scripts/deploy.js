const { ethers } = require("hardhat");

async function main() {
  console.log("Starting deployment process...");

  // Define the minimum stake required (0.01 ETH in wei)
  const minimumStake = ethers.parseEther("0.01");
  
  // Deploy the contract
  const Project = await ethers.getContractFactory("Project");
  console.log("Deploying Quantum-Resistant Genetic Algorithm Oracle Network...");
  
  const project = await Project.deploy(minimumStake);
  await project.waitForDeployment();
  
  const address = await project.getAddress();
  console.log("Contract deployed at:", address);
  
  console.log("Verifying contract on explorer...");
  console.log("Verification command:");
  console.log(`npx hardhat verify --network coreTestnet ${address} ${minimumStake}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
