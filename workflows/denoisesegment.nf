/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 */
include { paramsSummaryMap                  } from 'plugin/nf-schema'
include { softwareVersionsToYAML            } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText            } from '../subworkflows/local/utils_nfcore_denoisesegment_pipeline'
include { IMAGE_TRAIN_PREDICT_N2V_CAREAMICS } from '../subworkflows/careamics/image_train_predict_n2v_careamics/main'
include { CELLPOSE                          } from '../modules/nf-core/cellpose/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 */

workflow DENOISESEGMENT {
    take:
    ch_input // channel: input read in from --input
    outdir

    main:

    def experiment_name = "nf-run-${workflow.runName}"

    // Meta
    def meta = [id: workflow.runName]

    // CAREamics config channel
    ch_config = channel.of(
        [
            meta,
            experiment_name,
            "tiff",
            params.careamics_axes,
            params.careamics_patch_size,
            params.careamics_batch_size,
        ]
    )
    // CAREamics training data channel
    ch_training = channel.of(
        [meta, file(params.input), params.careamics_val_data ? file(params.careamics_val_data) : []]
    )
    // CAREamics prediction
    ch_prediction_data = channel.of(
        [meta, file(params.input)]
    )

    IMAGE_TRAIN_PREDICT_N2V_CAREAMICS(ch_config, ch_training, ch_prediction_data)

    ch_n2v_preds = IMAGE_TRAIN_PREDICT_N2V_CAREAMICS.out.predictions.flatMap { careamics_meta, files ->
        files.collect { file ->
            tuple(
                careamics_meta + [id: "${careamics_meta.id}_${file.baseName}"],
                file
            )
        }
    }

    CELLPOSE(ch_n2v_preds, [])

    def ch_versions = channel.empty()

    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [process[process.lastIndexOf(':') + 1..-1], "  ${tool}: ${version}"]
        }
        .groupTuple(by: 0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name: 'denoisesegment_software_' + 'versions.yml',
            sort: true,
            newLine: true,
        )

    emit:
    versions = ch_collated_versions
    segmentations = CELLPOSE.out.mask
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 */
