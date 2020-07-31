# How It Works

1. Deploy the Main.sol contract with gas price not less than 6700000

2. Use the createNewOrganization function to create a new organization / parking lot / event

3. Collect the address from step 2 generated organization and deploy contract ControlPanel to enable interaction with the Organization

4. After deploying ControlPanel in step 3, verify the ownership with the provided function call, if you created the Organization in step 2, You will be verified and you can now interact with your "Organization" from the control panel.


[FlowChart](https://github.com/rexdavinci/Ticketing/blob/master/Ticketer/Ticketer.png)

[Code](https://github.com/rexdavinci/Ticketing/tree/master/Ticketer)
