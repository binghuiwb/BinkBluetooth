//
//  ViewController.m
//  BinkBluetooth
//
//  Created by 王兵 on 2017/1/11.
//  Copyright © 2017年 Bink. All rights reserved.
//

#import "ViewController.h"

#import <CoreBluetooth/CoreBluetooth.h>


#define VIEWWIDTH self.view.frame.size.width
#define VIEWHEIGHT self.view.frame.size.height

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate,CBCentralManagerDelegate,CBPeripheralDelegate> {
    UITableView *_tableView;
    NSMutableArray *_dataArr;//存储所有搜索到得设备
    
    NSMutableArray *uuidsArr;//存储uuid
    
    NSMutableArray *peripheralArr;//存储已配对的设备
    NSMutableDictionary *peripheralDic;//存储配对设备的信息
    
    NSTimer *timer;//点击搜索，进行8秒搜索时间
    
    NSMutableArray *_charactersArr;//保存搜索到得character
    
    BOOL isPrinting; //判断特征值是否可以打印
    
    NSString *_haveConnectPeripherIdentify;//已连接设备的identify
}

@property (nonatomic,strong) CBPeripheral *peripheral;
@property (nonatomic,strong) CBCharacteristic *characteristic;
@property (nonatomic,strong) CBCentralManager *centralManager;



@end

@implementation ViewController




- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"");
    
    _dataArr = [[NSMutableArray alloc] init];
    _charactersArr = [[NSMutableArray alloc] init];
    isPrinting = YES;
    
    //默认已连接设备
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    peripheralArr = [NSMutableArray arrayWithArray:[userDefaults valueForKey:@"havePares"]];
    if (peripheralArr.count > 0) {
        _haveConnectPeripherIdentify = peripheralArr[0][@"identify"];
        
    }
    
    self.centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];
    
    [self initUI];
}

- (void)initUI {
    
    self.navigationItem.title = @"蓝牙打印";
    
    NSString *titleName = [NSString stringWithFormat:@"%@",@"搜索设备"];
    
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightBtn setTitle:titleName forState:UIControlStateNormal];
    [rightBtn.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [rightBtn setFrame:CGRectMake(0, 0, 18*[titleName length], 44)];
    [rightBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(doRightAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, VIEWWIDTH, VIEWHEIGHT) style:UITableViewStyleGrouped];
    _tableView.sectionHeaderHeight = 0.01;
    _tableView.sectionFooterHeight = 0.01;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.view addSubview:_tableView];
    
    if ([_tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        
        [_tableView   setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];
        
    }
    if ([_tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        
        [_tableView setLayoutMargins:UIEdgeInsetsMake(0, 0, 0, 0)];
        
    }
    
    //底部测试打印
    UIButton *footBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    footBtn.frame = CGRectMake(0, VIEWHEIGHT - 114, VIEWWIDTH, 50);
    
    [footBtn setTitle:@"测试打印" forState:UIControlStateNormal];
    [footBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [footBtn setImage:[UIImage imageNamed:@"蓝牙测试打印图标"] forState:UIControlStateNormal];
    footBtn.imageEdgeInsets = UIEdgeInsetsMake(0, -20, 0, 0);
    
    footBtn.tag = 100;
    [footBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:footBtn];
}

- (void)doRightAction:(UIButton *)sender {
    [self startScan];
}

- (void)startScan {
    [self.centralManager stopScan];
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    
    if (timer) {
        [timer invalidate];
    }
    
    timer = [NSTimer scheduledTimerWithTimeInterval:8
                                             target:self
                                           selector:@selector(scanStop)
                                           userInfo:nil
                                            repeats:NO];
    
}

//停止搜索
- (void)scanStop {
    [_centralManager stopScan];
    [timer invalidate];
}



#pragma mark - 蓝牙状态
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@">>>CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@">>>CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@">>>CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@">>>CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@">>>CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn:
        {
            NSLog(@">>>CBCentralManagerStatePoweredOn");
            //当前蓝牙已打开
            
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                
            } else {
                [self startScan];
            }
            
        }
            break;
        default:
            break;
    }
    
}

//扫描到设备会进入方法
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    NSLog(@"Did discover peripheral. peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ ", peripheral, RSSI, peripheral.identifier, advertisementData[@"kCBAdvDataServiceUUIDs"]);
    
    if ([_haveConnectPeripherIdentify isEqualToString:peripheral.identifier.UUIDString]) {
        
        self.peripheral = peripheral;
        [self.centralManager connectPeripheral:self.peripheral options:nil];
        
        [_centralManager connectPeripheral:peripheral  options:nil];
        
        if ([_dataArr containsObject:peripheral]) {
            [_dataArr removeObject:peripheral];
        }
        
    } else {
        
        if (![_dataArr containsObject:peripheral]) {
            [_dataArr addObject:peripheral];
        }
    }
    
    [_tableView reloadData];
    
}

//连接到Peripherals-成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self scanStop];
    //保存
    uuidsArr = [[NSMutableArray alloc] init];
    peripheralDic = [[NSMutableDictionary alloc] init];
    
    peripheral.delegate = self;
    [central stopScan];
    [peripheral discoverServices:nil];
    
    NSLog(@">>>外设连接 %@\n", [peripheral name]);
}

//连接到Peripherals-失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    _characteristic = nil;
    _peripheral = nil;
    
    NSLog(@">>>连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]);
}

//Peripherals断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    _characteristic = nil;
    _peripheral = nil;
    
    NSLog(@">>>外设连接断开连接 %@: %@\n", [peripheral name], [error localizedDescription]);
    //停止扫描
    [central stopScan];
    //断开连接
    [central cancelPeripheralConnection:peripheral];
    
    [self startScan];
}

#pragma mark - 扫描到服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    
    for (CBService *service in peripheral.services)
    {
        [peripheral discoverCharacteristics:nil forService:service];
        
        
        NSLog(@"Service found with UUID: %@", service.UUID);
    }
}

//扫描到特征
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    
    if (error)
    {
        NSLog(@"Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    
    for (CBCharacteristic * characteristic in service.characteristics)
    {
        
        if ((characteristic.properties & CBCharacteristicPropertyWrite) && isPrinting) {
            
            [peripheralArr removeAllObjects];
            
            _peripheral = peripheral;
            _characteristic = characteristic;
            
            [_charactersArr addObject:characteristic];
            
            NSLog(@"Discovered characteristics for%@",characteristic.UUID.UUIDString);
            
            for (CBService *servic in peripheral.services) {
                [uuidsArr addObject:servic.UUID.UUIDString];
            }
            
            [peripheralDic  setObject:uuidsArr forKey:@"uuid"];
            [peripheralDic setObject:peripheral.name ? peripheral.name : peripheral.identifier.UUIDString forKey:@"name"];
            [peripheralDic  setObject:peripheral.identifier.UUIDString forKey:@"identify"];
            _haveConnectPeripherIdentify = peripheral.identifier.UUIDString;
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            
            [peripheralArr insertObject:peripheralDic atIndex:0];
            
            [userDefaults setValue:peripheralArr forKey:@"havePares"];
            
            [userDefaults synchronize];
            
            [_dataArr removeObject:peripheral];
            
            [_tableView reloadData];
            
            isPrinting = NO;
            
            [self startScan];
        }
    }
}

//写入成功的回调
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
    NSLog(@"---%@---",characteristic.UUID);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 2;
}

#pragma mark - tableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return peripheralArr.count;
    } else {
        return _dataArr.count;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        
        [cell setSeparatorInset:UIEdgeInsetsZero];
        
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        
        [cell setLayoutMargins:UIEdgeInsetsZero];
        
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"cellID";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.textLabel.textColor = [UIColor blackColor];
    
    if (indexPath.section == 0) {
        if (peripheralArr.count > 0) {
            NSMutableDictionary *perDic = peripheralArr[0];
            cell.textLabel.text = perDic[@"name"];
        }
    } else {
        CBPeripheral *per = _dataArr[indexPath.row];
        
        if (per.name) {
            cell.textLabel.text = per.name;
        } else {
            cell.textLabel.text = [NSString stringWithFormat:@"未知设备%ld",(long)indexPath.row];
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        
        if (peripheralArr.count > 0) {
            return 40;
        } else {
            return 0.01;
        }
        
    } else {
        if (_dataArr.count > 0) {
            return 40;
        } else {
            return 0.01;
        }
        
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        
        if (peripheralArr.count > 0) {
            return 50;
        } else {
            return 0;
        }
        
    } else {
        if (_dataArr.count > 0) {
            return 50;
        } else {
            return 0;
        }
        
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1) {
        isPrinting = YES;
        [_centralManager connectPeripheral:_dataArr[indexPath.row]  options:nil];
    }
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    
    if (section == 0) {
        
        if (peripheralArr.count > 0) {
            return @"   默认连接的设备";
        } else {
            return @"";
        }
        
    } else {
        if (_dataArr.count > 0) {
            return @"   搜索到的设备";
        } else {
            return @"";
        }
        
    }
}

#pragma mark - 删除已配对设备
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
    
}

/*改变删除按钮的title*/
-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"删除";
}

/*删除用到的函数*/
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    _haveConnectPeripherIdentify = @"";
    
    [peripheralArr removeAllObjects];
    
    [[NSUserDefaults standardUserDefaults] setValue:peripheralArr forKey:@"havePares"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [tableView reloadData];
    
    if (_peripheral) {
        [_centralManager cancelPeripheralConnection:_peripheral];
    }
    
}


#pragma mark - 测试打印
- (void)btnClick:(UIButton *)btn {
    
    NSMutableArray *sendDataArray = [[NSMutableArray alloc] init];
    
    [sendDataArray addObject:@"云门店打印测试:iOS"];
    [sendDataArray addObject:[NSDate date]];
    
    [sendDataArray addObject:@""];
    [sendDataArray addObject:@""];
    
    if (btn.tag == 100) {
        if (_peripheral) {
            
            for (CBCharacteristic * characteristic in _charactersArr) {
                
                for (int i = 0; i < sendDataArray.count; i++) {
                    
                    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
                    
                    NSString *curPrintContent = [NSString stringWithFormat:@"%@",sendDataArray[i]];
                    NSString *printed = [curPrintContent stringByAppendingFormat:@"%c", '\n'];
                    
                    NSData  *data= [printed dataUsingEncoding: enc];
                    
                    [_peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                    
                }
                
            }
            
            return;
        }
        
    }
    
}

-(void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    if (_peripheral) {
        [_centralManager cancelPeripheralConnection:_peripheral];
    }
    
    self.centralManager = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
