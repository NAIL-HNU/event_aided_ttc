function result = plotSimpleResult(result, args, loopTimeStruct)
    switch args.calculationType
        case 'strttc'
            gtTTC = [result.gtTTC(:,2), result.gtTTC(:,5)];
            resultTime = result.strttcNonlinearTTC(:, 1);
        
            interpGtTTC = interp1(gtTTC(:, 1), gtTTC(:, 2), resultTime, 'linear', 'extrap');
            result.interpGtTTC = [resultTime, interpGtTTC];
        
            % strttc
            strttcRee = metricRee(interpGtTTC, result.strttcNonlinearTTC(:, 2));
            strttcMree = mean(strttcRee);
            result.strttcRee = strttcRee;
            result.strttcMree = strttcMree;

            % calculation time
            strttcMeanLinearTime = mean(result.strttcTimeCost(:, 2));
            strttcMeanNonlinearTime = mean(result.strttcTimeCost(:, 3));
            strttcMeanAllTime = mean(result.strttcTimeCost(:, 2) + result.strttcTimeCost(:, 3));
            result.strttcMeanLinearTime = strttcMeanLinearTime;
            result.strttcMeanNonlinearTime = strttcMeanNonlinearTime;
            result.strttcMeanAllTime = strttcMeanAllTime;
        
            resultFig = figure;
            plot(resultTime, interpGtTTC, '-*')
            hold on
            plot(result.strttcLinearTTC(:,1), result.strttcLinearTTC(:,2), '-*')
            plot(result.strttcNonlinearTTC(:,1), result.strttcNonlinearTTC(:,2), '-*')
            plot(result.strttcNonlinearTTC(:,1), result.strttcNonlinearTTC(:,3), '-*')
            hold off
            legend('GT TTC', 'Linear TTC', 'STR TTC', 'STR TTC GT')
            grid on
            xlabel('Time/s')
            ylabel('TTC')
            title(strcat(string(args.sequenceName), ' RMSE: strttcMree: ', string(strttcMree), "Cost Time: ", string(strttcMeanAllTime)));
            savefig(resultFig, fullfile(args.saveStrttcDir, 'ttcResult.fig'), "compact")
            saveas(resultFig, fullfile(args.saveStrttcDir, 'ttcResult.png'));
        
            reePlot = figure;
            plot(resultTime, strttcRee, '-*')
            legend('STR TTC')
            grid on
            xlabel('Time/s')
            ylabel('REE')
            title('REE')
            savefig(reePlot, fullfile(args.saveStrttcDir, 'reeResult.fig'), "compact")
            saveas(reePlot, fullfile(args.saveStrttcDir, 'reeResult.png'));



            fprintf(strcat("STR TTC Mean Linear Time: ", string(strttcMeanLinearTime), "STR TTC Mean Nonlinear Time: ", string(strttcMeanNonlinearTime), "STR TTC Mean All Time: ", string(strttcMeanAllTime), "\n"));

            % save result
            save(fullfile(args.saveStrttcDir, 'result.mat'), 'result');
            save(fullfile(args.saveStrttcDir, 'args.mat'), 'args');
            save(fullfile(args.saveStrttcDir, 'loopTimeStruct.mat'), 'loopTimeStruct');
        
        case 'cmax'
            gtTTC = [result.gtTTC(:,2), result.gtTTC(:,5)];
            resultTime = result.cmaxNonlinearTTC(:, 1);
        
            interpGtTTC = interp1(gtTTC(:, 1), gtTTC(:, 2), resultTime, 'linear', 'extrap');
            result.interpGtTTC = [resultTime, interpGtTTC];

            % cmax
            cmaxRee = metricRee(interpGtTTC, result.cmaxNonlinearTTC(:,2));
            cmaxMree = mean(cmaxRee);
            result.cmaxRee = cmaxRee;
            result.cmaxMree = cmaxMree;

            % calculation time
            cmaxMeanNonlinearTime = mean(result.cmaxTimeCost(:, 2));
            result.cmaxMeanNonlinearTime = cmaxMeanNonlinearTime;
            fprintf(strcat("CMax Mean Nonlinear Time: ", string(cmaxMeanNonlinearTime), "s\n"));

            resultFig = figure;
            plot(resultTime, interpGtTTC, '-*')
            hold on
            plot(result.cmaxNonlinearTTC(:,1), result.cmaxNonlinearTTC(:,2), '-*')
            hold off
            legend('GT TTC', 'CMax')
            grid on
            xlabel('Time/s')
            ylabel('TTC')
            title(strcat(string(args.sequenceName), ' RMSE: cmaxMree: ', string(cmaxMree), "Cost Time: ", string(cmaxMeanNonlinearTime) ));
            savefig(resultFig, fullfile(args.saveCmaxDir, 'ttcResult.fig'), "compact")
            saveas(resultFig, fullfile(args.saveCmaxDir, 'ttcResult.png'));
        
            reePlot = figure;
            plot(resultTime, cmaxRee, '-*')
            legend('camx TTC')
            grid on
            xlabel('Time/s')
            ylabel('REE')
            title('REE')
            savefig(reePlot, fullfile(args.saveCmaxDir, 'reeResult.fig'), "compact")
            saveas(reePlot, fullfile(args.saveCmaxDir, 'reeResult.png'));

            % save result
            save(fullfile(args.saveCmaxDir, 'result.mat'), 'result');
            save(fullfile(args.saveCmaxDir, 'args.mat'), 'args');
            save(fullfile(args.saveCmaxDir, 'loopTimeStruct.mat'), 'loopTimeStruct');


            gtTTC = [result.gtTTC(:,2), result.gtTTC(:,5)];
            resultTime = result.cmaxWithOurInitNonlinearTTC(:, 1);
        
            interpGtTTC = interp1(gtTTC(:, 1), gtTTC(:, 2), resultTime, 'linear', 'extrap');
            result.interpGtTTC = [resultTime, interpGtTTC];

            % cmax with our init
            cmaxWithOurInitRee = metricRee(interpGtTTC, result.cmaxWithOurInitNonlinearTTC(:,2));
            cmaxWithOurInitMree = mean(cmaxWithOurInitRee);
            result.cmaxWithOurInitMree = cmaxWithOurInitMree;

            % calculation time
            cmaxWithOurInitMeanLinearTime = mean(result.cmaxWithOurInitTimeCost(:, 2));
            cmaxWithOurInitMeanNonlinearTime = mean(result.cmaxWithOurInitTimeCost(:, 3));
            cmaxWithGtInitMeanNonlinearTime = mean(result.cmaxWithOurInitTimeCost(:, 4));
            cmaxWithOurInitMeanAllTime = mean(result.cmaxWithOurInitTimeCost(:, 2) + result.cmaxWithOurInitTimeCost(:, 3));
            result.cmaxWithOurInitMeanLinearTime = cmaxWithOurInitMeanLinearTime;
            result.cmaxWithOurInitMeanNonlinearTime = cmaxWithOurInitMeanNonlinearTime;
            result.cmaxWithOurInitMeanAllTime = cmaxWithOurInitMeanAllTime;

            resultFig = figure;
            plot(resultTime, interpGtTTC, '-*')
            hold on
            plot(result.cmaxWithOurInitLinearTTC(:,1), result.cmaxWithOurInitLinearTTC(:,2), '-*')
            plot(result.cmaxWithOurInitNonlinearTTC(:,1), result.cmaxWithOurInitNonlinearTTC(:,2), '-*')
            plot(result.cmaxWithOurInitNonlinearTTC(:,1), result.cmaxWithOurInitNonlinearTTC(:,3), '-*')
            hold off
            legend('GT TTC', 'Linear TTC', 'CMax with Our Init', 'CMax with GT Init')
            grid on
            xlabel('Time/s')
            ylabel('TTC')
            title(strcat(string(args.sequenceName), ' RMSE: cmaxWithOurInitMree: ', string(cmaxWithOurInitMree), "Cost Time: ourInit", string(cmaxWithOurInitMeanAllTime), 'gt init cost time: ', string(cmaxWithGtInitMeanNonlinearTime)));
            savefig(resultFig, fullfile(args.saveCmaxWithOurInitDir, 'ttcResult.fig'), "compact")
            saveas(resultFig, fullfile(args.saveCmaxWithOurInitDir, 'ttcResult.png'));
        
            reePlot = figure;
            plot(resultTime, cmaxWithOurInitRee, '-*')
            legend('CMax with Our Init')
            grid on
            xlabel('Time/s')
            ylabel('REE')
            title('REE')
            savefig(reePlot, fullfile(args.saveCmaxWithOurInitDir, 'reeResult.fig'), "compact")
            saveas(reePlot, fullfile(args.saveCmaxWithOurInitDir, 'reeResult.png'));

            % save result
            save(fullfile(args.saveCmaxWithOurInitDir, 'result.mat'), 'result');
            save(fullfile(args.saveCmaxWithOurInitDir, 'args.mat'), 'args');
            save(fullfile(args.saveCmaxWithOurInitDir, 'loopTimeStruct.mat'), 'loopTimeStruct');
            
            fprintf(strcat("------------------------------------------------------------------------------------", "\n"));
            fprintf(strcat(string(args.sequenceName), ' Events Num: ', string(args.fixedEventsNumber), "\n"));
            fprintf(strcat('cmaxMree:            RMSE: ', string(result.cmaxMree), "  Cost-Time: ", string(result.cmaxMeanNonlinearTime),"\n"));
            fprintf(strcat('cmaxWithOurInitMree: RMSE: ', string(result.cmaxWithOurInitMree), "  Cost-Time-ourInit", string(result.cmaxWithOurInitMeanAllTime), '  gt-init-cost-time: ', string(cmaxWithGtInitMeanNonlinearTime), '\n'));
    end
end