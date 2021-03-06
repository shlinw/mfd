//
//  ViewController.m
//  GuiSearch
//
//  Created by Shlin on 2017/2/5.
//

#import "ViewController.h"

NSString *mfd_data;
NSMutableDictionary *save_cmd_dict;

NSString *home_path;
NSString *data_path;
NSString *result_path;

@implementation ViewController

- (void)combobox_init {
    
    int8_t month_num = 1;
    int8_t year_num = 0;
    
    [self.md_start_month setStringValue:@"1月1日"];
    [self.md_stop_month setStringValue:@"今天"];
    [self.cr_start_month setStringValue:@"1月日"];
    [self.cr_stop_month setStringValue:@"1月日"];
    for (; month_num <= 12; month_num++) {
        NSString *month = [NSString stringWithFormat:@"%d月1日", month_num];
        [self.md_start_month addItemWithObjectValue: month];
        [self.md_stop_month addItemWithObjectValue: month];
        [self.cr_start_month addItemWithObjectValue: month];
        [self.cr_stop_month addItemWithObjectValue: month];
    }
    
    //get system time
    NSDate * date = [NSDate date];
    NSTimeInterval sec = [date timeIntervalSinceNow];
    NSDate * currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
    
    //print date with format, here only print year
    NSDateFormatter * df = [[NSDateFormatter alloc] init ];
    [df setDateFormat:@"yyyy"];
    NSString * na = [df stringFromDate:currentDate];
    
    NSString *str_year = [NSString stringWithFormat:@"%d年", na.intValue];
    [self.md_start_year setStringValue:str_year];
    [self.md_stop_year setStringValue:str_year];
    for (; year_num < 3; year_num++) {
        str_year = [NSString stringWithFormat:@"%d年", na.intValue - year_num];
        [self.md_start_year addItemWithObjectValue: str_year];
        [self.md_stop_year addItemWithObjectValue: str_year];
    }
    
#if 0
    //init tags select
    NSString *tags_cmd = [NSString stringWithFormat: @"defaults read com.apple.finder.plist ViewSettingsDictionary | grep -E \'.*_Tag_ViewSettings\'"];
    
    NSString *tags_result = [self performSelector:@selector(run_cmd:) withObject:tags_cmd];
    
    while(1) {
        if ([tags_result length] == 0)
            break;
        NSRange range=[tags_result rangeOfString:@"\n"];
        NSString *tags = [tags_result substringToIndex:range.location];
        NSLog(@"tags is: %@", tags);
        
        tags = [NSString stringWithFormat:@"%@\n", tags_result];
        NSError *error;
        NSRegularExpression *regex = [NSRegularExpression
                                      regularExpressionWithPattern:@"\"(.*)_Tag_ViewSettings"
                                      options:0
                                      error:&error];
        if (!error) { 
            NSTextCheckingResult *match = [regex firstMatchInString:tags
                                                            options:0
                                                              range:NSMakeRange(0, [tags length])];
            if (match) {
                NSRange matchRange = [match rangeAtIndex:1];
                NSString *key = [tags substringWithRange:matchRange];
               
                key = [key stringByReplacingOccurrencesOfString :@"\\\\U" withString:@"\\u"];
                
                NSString* esc1 = [key stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
                NSString* esc2 = [esc1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
                NSString* quoted = [[@"\"" stringByAppendingString:esc2] stringByAppendingString:@"\""];
                NSData* data = [quoted dataUsingEncoding:NSUTF8StringEncoding];
                NSString* unesc = [NSPropertyListSerialization propertyListFromData:data
                                                                   mutabilityOption:NSPropertyListImmutable format:NULL
                                                                   errorDescription:NULL];
                assert([unesc isKindOfClass:[NSString class]]);
                NSLog(@"Output = %@", unesc);
                
                [self.tags_select addItemWithObjectValue: unesc];
            }
        } else {
            NSLog(@"error - %@", error);
        }
        tags_result = [tags_result substringFromIndex:(range.location + 1)];
    }
#endif
    
    //init tags option
    NSString *filePath = [NSString stringWithFormat:@"%@Library/SyncedPreferences/com.apple.finder.plist", home_path];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
        NSArray *plistArray = plistDict[@"values"][@"FinderTagDict"][@"value"][@"FinderTags"];
        
        for (int i = 0; i < [plistArray count]; i++) {
            NSString *tag = [plistArray[i] objectForKey:@"n"];
            [self.tags_select addItemWithObjectValue: tag];
        }
    } else {
        NSLog(@"plist file does not exsit");
    }
    
    NSString *tmp = @"no tag";
    [self.tags_select setStringValue:tmp];
}

- (void)save_list_combobox_init {

    save_cmd_dict = [NSMutableDictionary dictionary];

    NSString *filePath = [NSString stringWithFormat:@"%@/GuiSearch.txt", data_path];
    
    NSFileManager *file = [NSFileManager defaultManager];
    if ([file fileExistsAtPath:filePath]) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
        [fileHandle seekToFileOffset:0];
        NSData *data =[fileHandle readDataToEndOfFile];
        NSString *str_data = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"str = %@", str_data);
        [fileHandle closeFile];
        
        while (1) {
            if ([str_data length] == 0)
                break;
            NSRange range=[str_data rangeOfString:@"\n"];
            NSString *str_cmd = [str_data substringToIndex:range.location];
            NSLog(@"cmd name is: %@", str_cmd);
            
            str_cmd = [NSString stringWithFormat:@"%@\n", str_cmd];
            
            NSError *error;
            NSRegularExpression *regex = [NSRegularExpression
                                          regularExpressionWithPattern:@"GuiSearchkey=(.*?),data=(.*?)\n"
                                          options:0
                                          error:&error];
            if (!error) { 
                NSTextCheckingResult *match = [regex firstMatchInString:str_cmd
                                                                options:0
                                                                  range:NSMakeRange(0, [str_cmd length])];
                if (match) {
                    NSRange matchRange = [match rangeAtIndex:1];
                    NSString *key = [str_cmd substringWithRange:matchRange];
                    NSLog(@"key = %@", key);
                    [self.save_list addItemWithObjectValue: key];
                    
                    
                    matchRange = [match rangeAtIndex:2];
                    NSString *cmd = [str_cmd substringWithRange:matchRange];
                    NSLog(@"cmd = %@", cmd);
                    
                    [save_cmd_dict setObject:cmd forKey:key];
                }
            } else {
                NSLog(@"error - %@", error);
            }
            
            str_data = [str_data substringFromIndex:(range.location + 1)];
        }
        NSString *tmp = [self.save_list itemObjectValueAtIndex:0];
        [self.save_list setStringValue:tmp];
    } else {
        NSLog(@"no file to show");
    }
}

- (void)check_file_path {
    home_path = [self performSelector:@selector(run_cmd:) withObject:@"echo $HOME"];
    home_path = [home_path stringByReplacingOccurrencesOfString :@"\n" withString:@"/"];
    NSLog(@"home path is %@", home_path);
    
    NSString *tmp_path = [NSString stringWithFormat:@"%@GuiSearch",home_path];
    
    NSFileManager *file = [NSFileManager defaultManager];
    if ([file fileExistsAtPath:tmp_path]) {
        NSLog(@"文件已存在");
    } else {
        BOOL sucess = [file createDirectoryAtPath:home_path withIntermediateDirectories:YES attributes:nil error:NULL];
        if (sucess == 1) {
            NSLog(@"文件创建成功");
        }else{
            NSLog(@"文件创建失败");
        }
    }
    
    data_path = [NSString stringWithFormat:@"%@/data", tmp_path];
    if ([file fileExistsAtPath:data_path]) {
        NSLog(@"文件已存在");
    } else {
        BOOL sucess = [file createDirectoryAtPath:data_path withIntermediateDirectories:YES attributes:nil error:NULL];
        if (sucess == 1) {
            NSLog(@"文件创建成功");
        }else{
            NSLog(@"文件创建失败");
        }
    }
    
    result_path = [NSString stringWithFormat:@"%@/search_result", home_path];
    if ([file fileExistsAtPath:result_path]) {
        NSLog(@"文件已存在");
    } else {
        BOOL sucess = [file createDirectoryAtPath:result_path withIntermediateDirectories:YES attributes:nil error:NULL];
        if (sucess == 1) {
            NSLog(@"文件创建成功");
        }else{
            NSLog(@"文件创建失败");
        }
    }
    
    
}

NSThread *parse_thread;
NSString *str_file;
- (void)viewDidLoad {
    [super viewDidLoad];
    [self performSelector:@selector(check_file_path)];
    [self performSelector:@selector(combobox_init)];
    [self performSelector:@selector(save_list_combobox_init)];
    
    parse_thread = [[NSThread alloc]initWithTarget:self selector:@selector(parse_file_list:) object:str_file];
    // Do any additional setup after loading the view.
}

- (NSString*)run_cmd:(NSString*)cmd {
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    
    [task setArguments: @[@"-c", cmd]];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    
    
    NSString *string;
    string = [[NSString alloc] initWithData: data
                                   encoding: NSUTF8StringEncoding];
    
    return string;
    
}

- (NSString*)run_mdfind_cmd:(NSString*)input {
    NSString *str_mdf_cmd = [NSString stringWithFormat: @"mdfind \'%@\'", input];
    
    NSLog(@"the mdfind command is: %@", str_mdf_cmd);
    
    NSString *result = [self performSelector:@selector(run_cmd:) withObject:str_mdf_cmd];
    
    return result;
}

- (NSString*)run_ln_cmd:(NSString*)input {
    NSString *base_cmd_1 = @"ln -s";
    NSString *base_cmd_2 = result_path;
    
    NSString *cmd;

    input = [input stringByReplacingOccurrencesOfString :@" " withString:@"\\ "];
    input = [input stringByReplacingOccurrencesOfString :@"-" withString:@"\\-"];
    input = [input stringByReplacingOccurrencesOfString :@"&" withString:@"\\&"];
    NSRange range=[input rangeOfString:@"/" options:NSBackwardsSearch];

    NSString *file_name = [input substringFromIndex:range.location];
    NSLog(@"file name is: %@", file_name);
    
    
    cmd = [NSString stringWithFormat: @"%@ %@ %@/link_%@", base_cmd_1, input, base_cmd_2,[file_name substringFromIndex:1]];
    
    NSLog(@"the ln command is: %@", cmd);
    
    NSString *output = [self performSelector:@selector(run_cmd:) withObject:cmd];
    
    return output;
}

- (NSString*)parse_mfd_cmd{
    
    NSString *str_kw;
    NSString *str_md_time;
    NSString *str_combo_cmd;
    NSString *str_mfd_cmd;
    
    if ([self.save_list_select state] == 1) {
        NSInteger index = 0;
        index = [self.save_list indexOfSelectedItem];
        index = (index == -1) ? 0 : index;
        NSString *key = [self.save_list itemObjectValueAtIndex:index];
        str_mfd_cmd = [save_cmd_dict objectForKey:key];
    } else {
        //get the key words
        if ([self.text_kw stringValue].length != 0) {
            str_kw = [self.text_kw stringValue];
            if ([self.name_select state] == 0) {
                str_combo_cmd = [NSString stringWithFormat: @"(true) && (kMDItemTextContent == \"%@\" || kMDItemFSName ==\"*%@*\"cdw)", str_kw, str_kw];
                NSLog(@"keyword is: %@", str_combo_cmd);
            } else {
                str_combo_cmd = [NSString stringWithFormat: @"(true) && kMDItemFSName ==\"*%@*\"cdw", str_kw];
            }
        } else {
            str_combo_cmd = @"(true)";
        }
        
        //get the modify time
        if ([self.md_sel_coarse state] == 1) {
            NSInteger index = 0;
            index = [self.md_time_coarse indexOfSelectedItem];
            if (index == -1 || index == 0) {
                //all time
                str_md_time = @"(true)";
            } else {
                switch (index) {
                    case 1:
                        str_md_time = @">$time.this_week";
                        break;
                    case 2:
                        str_md_time = @">$time.this_month";
                        break;
                    case 3:
                        str_md_time = @">$time.this_month(-3)";
                        break;
                    case 4:
                        str_md_time = @">$time.this_month(-6)";
                        break;
                    case 5:
                        str_md_time = @">$time.this_year";
                        break;
                    default:
                        break;
                }
                index = [self.time_type indexOfSelectedItem];
                index = (index == -1) ? 0 : index;
                if (index == 0) {
                    str_md_time = [NSString stringWithFormat:@"kMDItemFSContentChangeDate%@", str_md_time];
                } else {
                    str_md_time = [NSString stringWithFormat:@"kMDItemFSCreationDate%@", str_md_time];
                }
                NSLog(@"coarse time string is: %@", str_md_time);
            }
        } else if ([self.md_sel_fine state] == 1) {
            NSString *year, *month, *time_st, *time_end;
            NSInteger index = 0;
            //get modify start time
            index = [self.md_start_year indexOfSelectedItem];
            index = (index == -1) ? 0 : index;
            year = [self.md_start_year itemObjectValueAtIndex:index];
            index = [self.md_start_month indexOfSelectedItem];
            index = (index == -1) ? 0 : index;
            month = [self.md_start_month itemObjectValueAtIndex:index];
            time_st = [NSString stringWithFormat:@"%@%@", year, month];
            
            //get modify end time
            index = [self.md_stop_year indexOfSelectedItem];
            index = (index == -1) ? 0 : index;
            year = [self.md_stop_year itemObjectValueAtIndex:index];
            index = [self.md_stop_month indexOfSelectedItem];
            index = (index == -1) ? 0 : index;
            month = [self.md_stop_month itemObjectValueAtIndex:index];
            
            if (index == 0) {
                NSDate *currentDate = [NSDate date];
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"YYYY年MM月dd日"];
                time_end = [dateFormatter stringFromDate:currentDate];
            } else {
                time_end = [NSString stringWithFormat:@"%@%@", year, month];
            }
            
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy年MM月dd日"];
            NSDate *date_st = [[NSDate alloc] init];
            NSDate *date_end = [[NSDate alloc] init];
            date_st = [formatter dateFromString:time_st];
            date_end = [formatter dateFromString:time_end];
            
            
            NSTimeInterval sec_st = [date_st timeIntervalSinceReferenceDate];
            NSLog(@"the start time interval is %f", sec_st);
            
            NSTimeInterval sec_end = [date_end timeIntervalSinceReferenceDate];
            NSLog(@"the end time interval is %f", sec_end);
            
            index = [self.time_type indexOfSelectedItem];
            index = (index == -1) ? 0 : index;
            if (index == 0) {
                str_md_time = [NSString stringWithFormat:@"kMDItemFSContentChangeDate>=%ld && kMDItemFSContentChangeDate<=%ld", (long)sec_st, (long)sec_end];
            } else {
                str_md_time = [NSString stringWithFormat:@"kMDItemFSCreationDate>=%ld && kMDItemFSCreationDate<=%ld", (long)sec_st, (long)sec_end];
            }
        }
        
        str_combo_cmd = [NSString stringWithFormat: @"%@ && %@", str_combo_cmd, str_md_time];
        
        //file type
        {
            NSString *app = @"com.apple.application-bundle";
            NSString *avi = @"public.avi";
            NSString *deb = @"org.debian.deb-archive";
            NSString *dmg = @"com.apple.disk-image-udif";
            NSString *doc = @"com.microsoft.word.doc";
            NSString *docx = @"org.openxmlformats.wordprocessingml.document";
            NSString *epub = @"org.idpf.epub-container";
            NSString *exe = @"com.microsoft.windows-executable";
            NSString *fla = @"dyn.ah62d4rv4ge80q5db";
            NSString *flv = @"com.adobe.flash.video";
            NSString *gem = @"dyn.ah62d4rv4ge80s3pr";
            NSString *gif = @"com.compuserve.gif";
            NSString *gz = @"org.gnu.gnu-zip-archive";
            NSString *html = @"public.html";
            NSString *iso = @"public.iso-image";
            NSString *jar = @"com.sun.java-archive";
            NSString *jpeg = @"public.jpeg";
            NSString *jpg = @"public.jpeg";
            NSString *keynote = @"com.apple.iwork.keynote.sffkey";
            NSString *m4v = @"com.apple.m4v-video";
            NSString *mail = @"com.apple.mail.emlx";
            NSString *mov = @"com.apple.quicktime-movie";
            NSString *mp3 = @"public.mp3";
            NSString *mp4 = @"public.mpeg-4";
            NSString *numbers = @"com.apple.iwork.numbers.sffnumbers";
            NSString *pages = @"com.apple.iwork.pages.sffpages";
            NSString *pdf = @"com.adobe.pdf";
            NSString *pkg = @"com.apple.installer-package-archive";
            NSString *png = @"public.png";
            NSString *ppt = @"com.microsoft.powerpoint.ppt";
            NSString *pptx = @"org.openxmlformats.presentationml.presentation";
            NSString *rar = @"com.rarlab.rar-archive";
            NSString *rm = @"com.real.realmedia";
            NSString *rmvb = @"org.niltsh.mplayerx-rmvb";
            NSString *sqlite3 = @"dyn.ah62d4rv4ge81g6pqrf4gnq2";
            NSString *tar = @"public.tar-archive";
            NSString *tiff = @"public.tiff";
            NSString *txt = @"public.plain-text";
            NSString *war = @"com.sun.web-application-archive";
            NSString *web = @"com.apple.safari.history";
            NSString *xls = @"com.microsoft.excel.xls";
            NSString *xlsx = @"org.openxmlformats.spreadsheetml.sheet";
            NSString *zip = @"public.zip-archive";
            
            NSString *str_file_type;
            NSInteger index;
            index = [self.file_type indexOfSelectedItem];
            index = (index == -1) ? 0 : index;
            
            if (index == 0) {
                //do nothing
            } else {
                switch (index) {
                    case 1:
                        //doc, docx, pages
                        str_file_type = [NSString stringWithFormat:
                                         @"kMDItemContentType == %@ || kMDItemContentType == %@ || kMDItemContentType == %@", doc, docx, pages];
                        break;
                    case 2:
                        //xls, xlsx, numbers
                        str_file_type = [NSString stringWithFormat:
                                         @"kMDItemContentType == %@ || kMDItemContentType == %@ || kMDItemContentType == %@", xls, xlsx, numbers];
                        break;
                    case 3:
                        //ppt, pptx, keynote 
                        str_file_type = [NSString stringWithFormat:
                                         @"kMDItemContentType == %@ || kMDItemContentType == %@ || kMDItemContentType == %@", ppt, pptx, keynote];
                        break;
                    case 4:
                        //pdf
                        str_file_type = [NSString stringWithFormat:
                                         @"kMDItemContentType == %@", pdf];
                        break;
                    case 5:
                        //gif, jpeg, jpg, png 
                        str_file_type = [NSString stringWithFormat:
                                         @"kMDItemContentType == %@ || kMDItemContentType == %@ || kMDItemContentType == %@ || kMDItemContentType == %@", gif, jpeg, jpg, png];
                        break;
                    case 6:
                        //mp3, mp4 
                        str_file_type = [NSString stringWithFormat:
                                         @"kMDItemContentType == %@", mp3];
                        break;
                    case 7:
                        //avi, flv, m4v, mov, rmvb, mp4
                        str_file_type = [NSString stringWithFormat:
                                         @"kMDItemContentType == %@ || kMDItemContentType == %@ || kMDItemContentType == %@ || kMDItemContentType == %@ || kMDItemContentType == %@", avi, flv, m4v, rmvb, mp4];
                        break;
                    default:
                        break;
                }
                str_combo_cmd = [NSString stringWithFormat:@"%@ && (%@)", str_combo_cmd, str_file_type];
            }
        }
        
        //tags
        {
            NSInteger index;
            index = [self.tags_select indexOfSelectedItem];
            index = (index == -1) ? 0 : index;
            
            if (index == 0) {
               //do nothing
            } else {
                NSString *tag = [self.tags_select itemObjectValueAtIndex:index];
                tag = [NSString stringWithFormat:@"kMDItemUserTags = %@", tag];
                str_combo_cmd = [NSString stringWithFormat:@"%@ && (%@)", str_combo_cmd, tag];
            }
            
        }
        
        str_mfd_cmd = [NSString stringWithFormat: @"mdfind \'%@\'", str_combo_cmd];
        
    }
    
    NSLog(@"the mdfind command is: %@", str_mfd_cmd);
    
    return str_mfd_cmd;
}

NSInteger parse_thread_flag;
- (void)parse_file_list:(NSString*)file_list {
    file_list = str_file;
    
    
    NSString *clear = [NSString stringWithFormat:@"rm -r %@", result_path];
    NSString *result_clear = [self performSelector:@selector(run_cmd:) withObject:clear];
    
    [self performSelector:@selector(check_file_path)];
    
    while (1) {
        if ([file_list length] == 0)
            break;
        NSRange range = [file_list rangeOfString:@"\n"];
        
        NSString *file_path = [file_list substringToIndex:range.location];

        NSLog(@"the file path is:%@", file_path);
        
        NSString *file_name = [self performSelector:@selector(run_ln_cmd:) withObject:file_path];
        
        NSLog(@"the length is:%d %d", range.location, [file_list length]);
        NSLog(@"the rest is:%@", file_list);
        file_list = [file_list substringFromIndex:(range.location + 1)];
    }
    
    
    [self.run_search setStringValue:@"搜索完成"];
    [self.loading stopAnimation:nil];
    
    //open the finder
    NSString *file_url = [NSString stringWithFormat:@"open %@", result_path];
    NSString *result = [self performSelector:@selector(run_cmd:) withObject:file_url];
}

- (IBAction)button_click:(id)sender {
    
    NSString *command = [self performSelector:@selector(parse_mfd_cmd)];
    
    NSString *file_list = [self performSelector:@selector(run_cmd:) withObject:command];
    
    
    NSLog(@"file list is:%@", file_list);
    str_file = file_list;
    
    [self.run_search setHidden:NO];
    [self.loading setHidden:NO];
    [self.loading setIndeterminate:YES];
    [self.loading setUsesThreadedAnimation:YES];
    [self.loading startAnimation:nil];
    
    if (parse_thread.isExecuting) {
//        if (!parse_thread.isFinished) {
            [parse_thread cancel];
//        }
    }
    
    parse_thread = [[NSThread alloc]initWithTarget:self selector:@selector(parse_file_list:) object:str_file];
    [parse_thread start];
    
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

- (IBAction)md_sel_coarse_click:(id)sender {
    if ([self.md_sel_coarse state] == 1) {
            [self.md_sel_fine setState:0];
    }
    NSLog(@"coarse state is %d %d",[self.md_sel_coarse state], [self.md_sel_fine state]);
}
- (IBAction)md_sel_fine:(id)sender {
    if ([self.md_sel_fine state] == 1) {
            [self.md_sel_coarse setState:0];
    }
    NSLog(@"fine state is %d %d",[self.md_sel_fine state], [self.md_sel_coarse state]);
}

- (IBAction)save_seach_click:(id)sender {
    //save the seach command
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    NSString *command = [self performSelector:@selector(parse_mfd_cmd)];
    mfd_data = command;
}


@end
