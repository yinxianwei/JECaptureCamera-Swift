//
//  JESPViewController.swift
//  JESelectPhoto
//
//  Created by 尹现伟 on 15/4/16.
//  Copyright (c) 2015年 尹现伟. All rights reserved.
//

import UIKit
import AssetsLibrary
import AVFoundation
import MobileCoreServices

let reuseIdentifier = "Cell";

let KEY_GROUPNAME = "groupName";
let KEY_PHOTOS    = "photos";
let KEY_SELECT    = "select"
let KEY_ALLPHOTOS = "全部照片"



@objc protocol JESPViewControllerDelegate:NSObjectProtocol{

    
    optional func SPViewControllerdidSelectImages(images:NSArray);
    
    optional func SPViewControllerCancle();
    
    optional func SPViewControllerError(error:NSError);
}


class JESPViewController: UICollectionViewController,UICollectionViewDelegateFlowLayout,UITableViewDataSource,UITableViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,MLImageCropDelegate,SCNavigationControllerDelegate {
    
    var delegate : JESPViewControllerDelegate?
    var maximumOfSelected:Int = 9;
    var allowsMultipleSelection:Bool?;
    
    
    private  var assetsLibrary:ALAssetsLibrary = ALAssetsLibrary();
    private  var photosArray:NSMutableArray = [];
    private  var selectPhotosCount:Int = 0;
    private  var tableView:UITableView = UITableView();
    private  var titleButton:UIButton = UIButton();
    private  var bgControl = UIControl();
    private  var selectIndexPaths:NSMutableArray = NSMutableArray();

    var groupId = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initToolBar();
        
        self.initTabView();
        
        self.initNavBar();
        
        self.initCollView();
        
        

//TODO: 可以加个load动画
        self.getAllPhotos({ (photos) -> () in
//TODO: 结束动画
            self.selectGroup(0);
            self.tableView.reloadData();
            }, errorBlock: { (error:NSError!) -> Void in
                
                
        });
    }
    
    func initNavBar(){
        
        if(self.navigationController?.navigationBar == nil){
            
            
        }else{
            
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: UIBarButtonItemStyle.Done, target: self, action: "dismiss:");
           
            self.titleButton.frame = CGRectMake(0, 0, 200, 30);
            self.titleButton.addTarget(self, action: "titleButtonClick", forControlEvents: UIControlEvents.TouchUpInside);
            self.navigationItem.titleView = self.titleButton;

            self.titleButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal);
            self.titleButton.setImage(UIImage(named: "camera_arrow"), forState: UIControlState.Normal);

            
        }
    }
    
    func initTabView(){
        
        bgControl.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height);
        bgControl.backgroundColor = UIColor.lightGrayColor();
        bgControl.alpha = 0.6;
        bgControl.hidden = true;
        bgControl.addTarget(self, action: "titleButtonClick", forControlEvents: UIControlEvents.TouchUpInside);
        self.view.addSubview(bgControl);

        self.tableView.frame = CGRectMake(0, -self.tableviewHeight(), self.view.frame.size.width, tableviewHeight());
        self.view.addSubview(self.tableView);
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell");
        self.tableView.backgroundColor = UIColor.whiteColor();
    }
    
    func initCollView(){

        self.collectionView?.scrollsToTop = false;

        self.view.backgroundColor = UIColor.whiteColor();
        
        self.collectionView?.backgroundColor = UIColor.clearColor();
        
        self.collectionView!.registerClass(JEPhotoCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        if self.allowsMultipleSelection == true {
            self.collectionView?.frame = CGRectMake(self.collectionView!.frame.origin.x, self.collectionView!.frame.origin.y, self.collectionView!.frame.size.width, self.collectionView!.frame.size.height - 40);
        }
    }
    
    func initToolBar(){
        if self.allowsMultipleSelection == true{
            var toolBarBgImageView = UIImageView(frame: CGRectMake(0, self.view.frame.size.height - 20, self.view.frame.size.width, 40));
            toolBarBgImageView.userInteractionEnabled = true;
            toolBarBgImageView.image = UIImage(named: "order_search_bar_bg");
            self.view.addSubview(toolBarBgImageView);
            toolBarBgImageView.backgroundColor = UIColor.clearColor();
            
            var nextButton = UIButton(frame: CGRectMake(self.view.frame.width - 80, 5, 70, 30));
            toolBarBgImageView.addSubview(nextButton);
            
            nextButton.setTitle("下一步", forState: UIControlState.Normal);
            nextButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal);
            nextButton.setBackgroundImage(UIImage(named: "exception"), forState: UIControlState.Normal);
            nextButton.addTarget(self, action: "nextClick:", forControlEvents: UIControlEvents.TouchUpInside);
        }
    }
    
    func titleButtonClick() {
        
        self.titleButton.selected = !self.titleButton.selected;
        self.bgControl.hidden = !self.bgControl.hidden;
        
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.titleButton.imageView?.transform = CGAffineTransformMakeRotation(self.titleButton.selected ? CGFloat(M_PI) : 0 );
            
            self.tableView.frame = CGRectMake(0, self.titleButton.selected ? 64 : -self.tableviewHeight(), self.view.frame.size.width, self.tableviewHeight());
            
            }) { (ok :Bool) -> Void in

        }
    }
    
    func dismiss(sender:AnyObject){
        
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.delegate?.SPViewControllerCancle?();
        });
    }

    func nextClick(sender:AnyObject){
        
        if self.selectPhotosCount>0 && self.delegate != nil{
            var array = self.getAllSelectPhotos();
            
            self.delegate?.SPViewControllerdidSelectImages?(array);
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                
            });
        }
    }
    func getAllSelectPhotos() -> NSMutableArray{
        
        var array = NSMutableArray();
        
        for dict in self.photosArray{
            var ary = dict[KEY_PHOTOS] as! NSArray;
            if ary.count>0{
                for obj in ary{
                    let res = obj as! ALAsset;
                    if res.isSelect == true{
                        let image = UIImage(CGImage: res.defaultRepresentation().fullResolutionImage().takeUnretainedValue());
                        array.addObject(image!);
                    }
                }
            }
        }
        
        return array;
    }
    
    func openCamera( block:(image: UIImage)->() ) {

      
        
        
        let authStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo);
    
        
        if authStatus == AVAuthorizationStatus.Denied || authStatus == AVAuthorizationStatus.Restricted{
            
            self.delegate?.SPViewControllerError?(NSError(domain: "没有相机权限或设备无相机", code: -1, userInfo: nil));
            
        }
        else{
            
            var nav = SCNavigationController();
            nav.scNaigationDelegate = self;
            nav.showCameraWithParentController(self);
            
//            var picker = UIImagePickerController();
//            picker.delegate = self;
//            picker.allowsEditing = true;
//            picker.sourceType = UIImagePickerControllerSourceType.Camera;
//            
//            self.presentViewController(picker, animated: true) { () -> Void in
//                
//            };
        }
    }
    
//MARK: - SCNavigationControllerDelegate
    
    func didTakePicture(navigationController: SCNavigationController!, image: UIImage!) {
        
        self.delegate?.SPViewControllerdidSelectImages?([image]);

        var imageView = UIImageView(frame: CGRectMake(0, 0, self.view.frame.size.width, UIScreen.mainScreen().bounds.size.height));
        imageView.image = navigationController.view.getSnapshotImage();
        
        self.navigationController?.setNavigationBarHidden(true, animated: false);
        self.view.addSubview(imageView);
        
        navigationController.dismissViewControllerAnimated(false, completion: nil);
        self.dismissViewControllerAnimated(true, completion: nil);

    }
    
//MARK: - MLImageCropDelegate
    
    func cropImage(cropImage: UIImage!, forOriginalImage originalImage: UIImage!) {
       
        self.delegate?.SPViewControllerdidSelectImages?([cropImage]);
        self.dismissViewControllerAnimated(false, completion: { () -> Void in

        });

    }
    
//MARK: - UIImagePickerControllerDelegate
  
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        if self.delegate != nil{

            var type = info[UIImagePickerControllerMediaType] as! String;
            
            if type == String(kUTTypeImage) && picker.sourceType == UIImagePickerControllerSourceType.Camera{
                

                var image = info[(self.allowsMultipleSelection == true ? UIImagePickerControllerOriginalImage : UIImagePickerControllerEditedImage)] as! UIImage;
                var array = self.getAllSelectPhotos();
                array.addObject(image);
                self.delegate?.SPViewControllerdidSelectImages?(array);
                
            }else{
                
            }
        }
        
        var imageView = UIImageView(frame: CGRectMake(0, 0, self.view.frame.size.width, UIScreen.mainScreen().bounds.size.height));
        imageView.image = picker.view.getSnapshotImage();
        
        self.navigationController?.setNavigationBarHidden(true, animated: false);
        self.view.addSubview(imageView);
        
        picker.dismissViewControllerAnimated(false, completion: nil);
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    
    /**
    选择分组
    
    :param: index -1为全部
    */
    func selectGroup(index:Int){
        
        var dict = self.photosArray[index] as! NSDictionary;
        var titleStr = dict[KEY_GROUPNAME] as! String;
        
        self.titleButton.setTitle(titleStr, forState: UIControlState.Normal);

        
        self.groupId = index;
        
        self.collectionView?.reloadData();

        
    }
    // MARK: - UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.photosArray.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell;
        
        var dict = self.photosArray[indexPath.row] as! NSDictionary;
        var name = dict[KEY_GROUPNAME] as! String;
        cell.textLabel?.text = name;
        
        return cell;
    }
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true);
        
        self.titleButtonClick();
        
        var index = indexPath.row;
        
        if index != self.groupId{
            
            self.selectGroup(indexPath.row);
            

        }
        
    }

    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        return (self.photosArray.count > 0) ? 1 : 0;
    }
    
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        if groupId == -1{
            var count = 0;
            for dict in self.photosArray{
               count += (dict[KEY_PHOTOS] as! NSArray).count
            }
            return count+1;
        }
        else{
            var dict = self.photosArray[groupId] as! NSDictionary;
            return (dict[KEY_PHOTOS] as! NSArray).count+1;
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! JEPhotoCollectionViewCell
        
        if indexPath.row == 0{
            cell.imageView.image = UIImage(named: "LLReviewCamera");
            cell.selectButton.hidden = true;
            return cell;
        }
        
        var res = self.getAssetWithIndex(indexPath.row);
        var ref = res.thumbnail().takeUnretainedValue();
        
        cell.imageView.image =  UIImage(CGImage: ref);
        cell.selectPhoto = res.isSelect;
        if self.allowsMultipleSelection == true{
            cell.selectButton.hidden = false;
        }else{
            cell.selectButton.hidden = true;
        }

        
        return cell
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake((self.view.frame.width - 10) / 3, (self.view.frame.width - 10) / 3);
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets{
        
        return UIEdgeInsetsMake(5, 0, 5, 0);
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat{
        return 5;
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat{
        return 5;
    }
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row == 0{
            if self.selectPhotosCount >= self.maximumOfSelected && self.allowsMultipleSelection == true{
                
                return;
            }
            //相机
            self.openCamera({ (image:UIImage) -> () in
                
                
            });
        }
        else{
            if self.allowsMultipleSelection == true{
                
               
                
                var res = self.getAssetWithIndex(indexPath.row);
                
                if self.selectPhotosCount >= self.maximumOfSelected && res.isSelect != true{
                    return;
                }
                
                res.isSelect = !res.isSelect;
                self.selectPhotosCount += (res.isSelect == true ? 1 : -1);
                
                self.collectionView?.reloadData();
            
            }
            else{
                if (self.delegate != nil){
                    var res = self.getAssetWithIndex(indexPath.row);
                    let image = UIImage(CGImage: res.defaultRepresentation().fullResolutionImage().takeUnretainedValue());
                   
                    //>>===============裁剪===============<<
                    var imageCrop = MLImageCrop();
                    imageCrop.delegate = self;
                    imageCrop.ratioOfWidthAndHeight = 600.0/600.0;
                    
                    imageCrop.image = image;
                    
                    imageCrop.showWithAnimation(false);
                    //>>===============裁剪===============<<
                    
                }
            }
        
        }
    }
    
    
    func getAssetWithIndex(index:Int) -> ALAsset! {
        
        var res:ALAsset;
        
        var array = self.photosArray[groupId][KEY_PHOTOS] as! NSArray;
        res = array[index - 1] as! ALAsset;

        return res;
    }
    
    func getAssetInPhotosWithIndex(index:Int) -> ALAsset? {
        var count = 0;
        var i = 0;
        for dict in self.photosArray{
            var array = dict[KEY_PHOTOS] as! NSArray;
            if array.count>0{
                if ((count+array.count-1) >= index){
                    var res = array[index - count] as! ALAsset;

                    return res;
                }
                count += array.count;
                
                i++;
            }
        }
        return nil;
    }
    
    
    // MARK: - UICollectionViewDelegate
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
    }
    */
    
    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
    }
    */
    
    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return false
    }
    
    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
    return false
    }
    
    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
    


    
    func getAllPhotos(photoBlock:(photos:NSMutableArray)->(),errorBlock:ALAssetsLibraryAccessFailureBlock!){

        self.photosArray = NSMutableArray();
        
        self.assetsLibrary.enumerateGroupsWithTypes(ALAssetsGroupAll, usingBlock: { (group:ALAssetsGroup!, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
            if group != nil{
                
                var ary = NSMutableArray();
                group.enumerateAssetsUsingBlock({ (result:ALAsset!, index:Int, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
                    if (result != nil){

                        var assetType  = result.valueForProperty(ALAssetPropertyType) as! String;
                        
                        if assetType == ALAssetTypePhoto{
                            
                            ary.addObject(result);
                        
                        }
                        
                    }
                    else
                    {
                        
                        var dict = NSMutableDictionary(objects: [group.valueForProperty(ALAssetsGroupPropertyName),ary.reverseObjectEnumerator().allObjects,0], forKeys:[KEY_GROUPNAME,KEY_PHOTOS,KEY_SELECT] );
                        self.photosArray.insertObject(dict, atIndex: 0);
                    }
                    
                });

            }
            else{
                photoBlock(photos:self.photosArray);
            }
            }, failureBlock: errorBlock);
        
    }
    
    func tableviewHeight() -> CGFloat {
        return self.view.frame.size.height/2;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}





class JEPhotoCollectionViewCell:UICollectionViewCell {
    
    var imageView:UIImageView!;
    var selectButton:UIButton!;
    var _selectPhoto: Bool!;
    private var maskImageView:UIImageView!;
    
    
    var selectPhoto:Bool{
        get{
            return _selectPhoto;
        }
        set{
            if _selectPhoto != newValue{
                if newValue{
                    self.selectButton.setImage(UIImage(named: "fj_icon_filter_selected01"), forState: UIControlState.Normal);
                }
                else{
                    self.selectButton.setImage(UIImage(named: "LLPaySelectedNot"), forState: UIControlState.Normal);
                }
                self.maskImageView.hidden = !newValue;
            }
            _selectPhoto = newValue;
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.imageView = UIImageView(frame: CGRectMake(0, 0, frame.width, frame.height));
        self.contentView.addSubview(self.imageView);
        
        self.maskImageView = UIImageView();
        self.maskImageView.frame = self.imageView.frame;
        self.imageView.addSubview(self.maskImageView);
        self.maskImageView.hidden = true;
        self.maskImageView.alpha = 0.4;
        self.maskImageView.backgroundColor = UIColor.whiteColor();
        
        self.selectButton = UIButton(frame: CGRectMake(frame.size.width - 30, 0, 30, 30));
        self.selectButton.setImage(UIImage(named: "LLPaySelectedNot"), forState: UIControlState.Normal);
        self.contentView.addSubview(self.selectButton);
        self.selectButton.userInteractionEnabled = false;
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
    }
    
//    func supportedInterfaceOrientations() -> Int{
//
//        return Int(UIInterfaceOrientationMask.Portrait.rawValue);
//        }
//    func shouldAutorotate() -> Bool{
//        return true;
//    }
//    
//    func shouldAutorotateToInterfaceOrientation(interfaceOrientation:UIInterfaceOrientation) -> Bool{
//        
//           return (interfaceOrientation == UIInterfaceOrientation.Portrait);
//        
//    }
    
}


extension UIView{
    
     func getSnapshotImage() -> UIImage {
  
        UIGraphicsBeginImageContext(self.frame.size);
        self.layer.renderInContext(UIGraphicsGetCurrentContext());
        var image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image;
    }
}


extension ALAsset {
    private struct AssociatedKeys {
        static var DescriptiveName = false
    }
    
    var isSelect: Bool! {
        get {
            var obj = objc_getAssociatedObject(self, &AssociatedKeys.DescriptiveName) as? Bool;
            if obj == nil{
                return false;
            }
            return obj;
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.DescriptiveName,
                    newValue as Bool!,
                    UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                )
            }
        }
    }
}

