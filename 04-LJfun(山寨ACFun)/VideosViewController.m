//
//  VideosViewController.m
//  04-LJfun(山寨ACFun)
//
//  Created by  a on 16/3/31.
//  Copyright © 2016年 eva. All rights reserved.
//

#define LJURL(path)  [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:8080/MJServer/%@",path]]
#import "VideosViewController.h"
#import "MBProgressHUD+MJ.h"
#import "VideoModel.h"
#import "UIImageView+WebCache.h"
#import "GDataXMLNode.h"
// 苹果自带的视频播放器头文件 / iOS9已不推荐使用
#import <MediaPlayer/MediaPlayer.h>

@interface VideosViewController ()

@property (nonatomic, strong) NSMutableArray *videos;
@end

@implementation VideosViewController

- (NSMutableArray *)videos {
    if (!_videos) {
        self.videos = [NSMutableArray array];
    }
    return _videos;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 界面加载完毕后，应该加载服务器最新的视频信息
    // 1. 创建URL
    NSURL *url = LJURL(@"video?type=XML");
    // 2. 创建请求
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // 3. 发送请求
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        // 3.1 对服务器返回的数据进行判断
        if (connectionError || data == nil) {
            [MBProgressHUD showError:@"网络繁忙，请稍后再试"];
            return;
        }
#warning The diffence of XML and JSON 
#if 0
"本质是一样的，只是创建请求时候要求服务器返回的数据格式不一样，连带解析方法也不一样"
#endif
        // 4. 解析XML文档 (从github中下载的框架似乎删除了option的接口)
        // 4.1 加载整个XML文档
        GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithData:data error:nil];
        
        // 4.2 获取docu的根元素(根节点)
        GDataXMLElement *root = document.rootElement;
        
        // 4.3 获得根元素内的所有video元素 (返回一个数组)
        NSArray *elements = [root elementsForName:@"video"];
        
        // 4.4 遍历所有的video元素
        for (GDataXMLElement *videoElements in elements) {
            // 取出模型
            VideoModel *video = [[VideoModel alloc] init];
            // 取出元素的属性 (给模型的属性赋值)
            video.id = [videoElements attributeForName:@"id"].stringValue.intValue;
            video.length = [videoElements attributeForName:@"length"].stringValue.intValue;
            video.name = [videoElements attributeForName:@"name"].stringValue;
            video.image = [videoElements attributeForName:@"image"].stringValue;
            video.url = [videoElements attributeForName:@"url"].stringValue;
            
            // 将赋值好的属性添加到数组中
            [self.videos addObject:video];
        }
        
        // 5. 刷新表格
        [self.tableView reloadData];

    }];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.videos.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ID = @"videos";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID];
    }
    
    // 设置cell的属性
    VideoModel *video = self.videos[indexPath.row];
    
    cell.textLabel.text = video.name;
    NSURL *url = LJURL(video.image);
    [cell.imageView sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"placeholder"]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"视频时长: %d秒", video.length];
    
#warning change cell.imageView.frame.size to fixed value / 修改图片的尺寸为固定值
    // 修改cell.imageView 为固定尺寸
    CGSize size = CGSizeMake(85, 40);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGRect imageRect = CGRectMake(0, 0, size.width, size.height);
    [cell.imageView.image drawInRect:imageRect];
    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // cell.imageView.bounds = CGSizeMake(0, 0);
    return cell;

}

#pragma mark - 代理方法 (监听cell的点击)
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 1. 取出对应的视频模型 (根据行号取出视频)
    VideoModel *video = self.videos[indexPath.row];
    
    // 播放视频 (最简单的方法: 直接调用系统提供的视频播放器)
    // 2. 创建播放器 并设置播放的视频的路径
    NSURL *url = LJURL(video.url);
    MPMoviePlayerViewController *playerVc = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
    
    // 3. 显示播放器
    [self presentViewController:playerVc animated:YES completion:nil];
    
}


@end
